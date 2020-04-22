#!/usr/bin/perl

# use DateTime qw(:all);
# use DateTime::Calendar::Julian qw(:all);
use Getopt::Std;
use DateRDFUtils;
use warnings;
use strict;

## DateTime also handles "negative" Dates, i.e. "B.C"

our ($opt_h, $opt_l, $opt_f, $opt_t, $opt_d, $opt_H);
getopts('hl:f:t:dH');

my $DEFAULT_FROM = "1000-01-01";
my $DEFAULT_TO   = "3000-12-31";

sub usage {
  print <<"EOF";
USAGE $0 (-h) (-l <LIMIT>) (-D <DATE_START>)

Print RDF for all years starting with <DATE_FROM> up to <LIMIT> years or
up to <DATE_TO>.


OPTIONS:

-f <DATE_FROM>  Start with this date
               Format: (-)YYYY-MM-DD
             ( DEFAULT: $DEFAULT_FROM )
-t <DATE_TO>
             ( DEFAULT: $DEFAULT_TO )

-l <LIMIT>   Output at most <LIMIT> days

-H           Do NOT print RDF-header

-d           Debug mode

-h           Print this message

EOF
}

if ($opt_h) {
  usage();
  exit;
}

my $date;
my $datemax;
if ($opt_f) {
  $date = $opt_f;
} else {
  $date = $DEFAULT_FROM;
}
if ($opt_t) {
  $datemax= $opt_t;
} else {
  $datemax = $DEFAULT_TO;
}

## parse $date
my ($year, $month, $day) = ($date =~ m/^(-?\d\d\d\d)-(\d\d)-(\d\d)$/);
## parse $datemax
my ($yearmax, $monthmax, $daymax) = ($datemax =~ m/^(-?\d\d\d\d)-(\d\d)-(\d\d)$/);

### print header unless -H
print $DateRDFUtils::rdfstart unless ($opt_H);

###################
my $n = 0;
YEAR: for (my $yyyy=$year; $yyyy <= $yearmax; $yyyy++)  {
     ### only use years which end in "0" - ignore all others
     next YEAR unless  ( $yyyy =~ m/0$/ );

     last YEAR if ( $opt_l && ($opt_l <= $n++) );

     my $decade = DateRDFUtils::year2decade($yyyy);
     my $decadeplus = $decade + 1;
     my $decademinus = $decade - 1;

     #my $semium = DateRDFUtils::year2semium($yyyy);
     #my $semiumplus = $semium + 1;
     #my $onedigit = DateRDFUtils::year2onedigit($yyyy);
     #my $onedigitplus = $onedigit + 1;

     ## century and decade from year
     my ($cc,$dec) = ($yyyy =~ m/(-?\d{1,2})(\d\d)/);
     my $ccplus = $cc + 1;
     my $ccplusrev = $ccplus * -1;
     my $ccminus = $cc - 1;

     ## debug mode: only print $yyy & $ccth
     if ($opt_d) {
        print "year=$yyyy  decade=$decade\n"; next YEAR;
     }

     my $output = <<"EOF";
      <rdf:Description rdf:about="https://vocabs.acdh.oeaw.ac.at/date/$decade">
        <rdf:type rdf:resource="https://vocabs.acdh.oeaw.ac.at/unit_of_time/decade"/>
        <rdf:type rdf:resource="http://www.w3.org/2004/02/skos/core#Concept"/>
        <skos:inScheme rdf:resource="https://vocabs.acdh.oeaw.ac.at/date/conceptScheme"/>
        <skos:prefLabel xml:lang="en">${decade}0s</skos:prefLabel>
        <rdfs:label xml:lang="en">${decade}0s</rdfs:label>
        <skos:altLabel xml:lang="en">${decade}0/${decade}9</skos:altLabel>
        <skos:altLabel xml:lang="en">${decade}0-${decade}9</skos:altLabel>
        <skos:altLabel xml:lang="en">AD ${decade}0 - AD ${decade}9</skos:altLabel>
        <skos:definition xml:lang="en">A decade from ${decade}0 to ${decade}9 in ISO8601 (the Gregorian and proleptic Gregorian calendar). From AD ${decade}0 to AD ${decade}9.</skos:definition>
        <skos:note>With regard to Date Entity modelling, documentation should be consulted at https://vocabs.acdh-dev.oeaw.ac.at/date/. It incldues information about URI syntax, ISO8601 conventions, and data enrichment among others.</skos:note>
        <time:hasTRS rdf:resource="http://www.opengis.net/def/uom/ISO-8601/0/Gregorian"/>
        <skos:broader rdf:resource="https://vocabs.acdh.oeaw.ac.at/date/$ccplus"/>
        <time:intervalMeets rdf:resource="https://vocabs.acdh.oeaw.ac.at/date/$decadeplus"/>
        <time:intervalMetBy rdf:resource="https://vocabs.acdh.oeaw.ac.at/date/$decademinus"/>
      </rdf:Description>

EOF

  print "$output";

} ## for yyy


###
print $DateRDFUtils::rdfend unless ($opt_H);
