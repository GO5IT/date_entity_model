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

my $DEFAULT_FROM = "1901-01-01";
my $DEFAULT_TO   = "2000-12-31";

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

     last YEAR if ( $opt_l && ($opt_l <= $n++) );

     my $decade = DateRDFUtils::year2decade($yyyy);
     my $semium = DateRDFUtils::year2semium($yyyy);

     my $output = <<"EOF";
      <rdf:Description rdf:about="https://vocabs.acdh.oeaw.ac.at/date/$yyyy">
        <rdf:type rdf:resource="https://vocabs.acdh.oeaw.ac.at/unit_of_time/year"/>
        <rdf:type rdf:resource="http://www.w3.org/2004/02/skos/core#Concept"/>
        <skos:inScheme rdf:resource="https://vocabs.acdh.oeaw.ac.at/date/conceptScheme"/>
        <skos:prefLabel xml:lang="en">$yyyy</skos:prefLabel>
        <rdfs:label rdf:datatype="xsd:gYear">$yyyy</rdfs:label>
        <skos:definition xml:lang="en">Year $yyyy in ISO8601 (the Gregorian and proleptic Gregorian calendar)</skos:definition>
        <time:hasTRS rdf:resource="http://www.opengis.net/def/uom/ISO-8601/0/Gregorian"/>
        <skos:exactMatch rdf:resource="http://dbpedia.org/resource/$yyyy"/>
        <skos:exactMatch rdf:resource="http://semium.org/time/$yyyy"/>
        <skos:broader rdf:resource="http://semium.org/time/${semium}xx"/>
        <skos:broader rdf:resource="https://vocabs.acdh.oeaw.ac.at/date/$decade"/>
      </rdf:Description>

EOF

  print "$output";

} ## for yyy


###
print $DateRDFUtils::rdfend unless ($opt_H);
