#!/usr/bin/perl

    local ($buffer, @pairs, $pair, $name, $value, %FORM);
    # Read in text
    $ENV{'REQUEST_METHOD'} =~ tr/a-z/A-Z/;
    if ($ENV{'REQUEST_METHOD'} eq "POST")
    {
        read(STDIN, $buffer, $ENV{'CONTENT_LENGTH'});
    }else {
	$buffer = $ENV{'QUERY_STRING'};
    }
    # Split information into name/value pairs
    @pairs = split(/&/, $buffer);
    foreach $pair (@pairs)
    {
	($name, $value) = split(/=/, $pair);
	$value =~ tr/+/ /;
	$value =~ s/%(..)/pack("C", hex($1))/eg;
	$FORM{$name} = $value;
    }
    $first_name = $FORM{first_name};
    $last_name  = $FORM{last_name};

$pValues = $FORM{'pValues'};
my @lines = split('\n', $pValues);

chdir("scriptOutput");

open (OUTPUT, ">pValues.csv");
my $p;
foreach $p (@lines) {
	if (! ($p =~ /^[0-9]/)) { next; }
	if ($p =~ /[a-zA-Z]/) { next; }
	$p =~ s/\r//g; $p =~ s/\n//g;
	print OUTPUT "$p\n";		# THIS IS FOR R
	$| = 1;
	}
close(OUTPUT);

open (R_CODE, ">q_value_calculation.r");
print R_CODE 'library(qvalue);' . "\n";
print R_CODE 'p<-scan("pValues.csv");' . "\n";
print R_CODE 'qobj<-qvalue(p);' . "\n";					# This assumes the smoother method by Storey and Tibshirani (2003) for pi0 calculation
#print R_CODE 'qobj<-qvalue(p, pi0.method="bootstrap");' . "\n";
#print R_CODE 'qobj<-qvalue(p, lambda=0);' . "\n";			# Conservative q-value Benjamini Hochberg (1995) methodology
print R_CODE 'qwrite(qobj, filename="qValues.txt");';
close(R_CODE);
$| = 1;

my $success = system("R CMD BATCH q_value_calculation.r");		# This should generate qvalues.txt
$| = 1;

$day = (localtime)[3];
$month = (localtime)[4]+1;
$year = (localtime)[5]+1900;

my $dateString = $year . "_" . $month . "_" . $day;
my $fileName = "$dateString" . "_qValues.txt";

# FINAL OUTPUT IS RETURNED TO THE BROWSER AS A FILE
print "Content-Type: text/csv\n";
print "Content-Disposition: attachment; filename=$fileName\n\n";

open(OUTPUT, "qValues.txt");
my $firstLine = <OUTPUT>;
my $secondLine = <OUTPUT>;
while (my $line = <OUTPUT>) {
	$line =~ s/ /\t/g;
	print $line;
	}

system('rm pValues.csv');
system('rm qValues.txt');
system('rm q_value_calculation.r.Rout');
system('rm q_value_calculation.r');

exit;
