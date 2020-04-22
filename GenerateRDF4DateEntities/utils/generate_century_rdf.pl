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

my $DEFAULT_FROM = "-0900-01-01";
my $DEFAULT_TO   = "-0100-01-01";

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

     ### only use years which end in "00" - ignore all others
     next YEAR unless  ( $yyyy =~ m/00$/);

     last YEAR if ( $opt_l && ($opt_l <= $n++) );

     my $decade = DateRDFUtils::year2decade($yyyy);
     my $semium = DateRDFUtils::year2semium($yyyy);
     my $semiumplus = $semium + 1;
     my $onedigit = DateRDFUtils::year2onedigit($yyyy);
     #my $onedigitplus = $onedigit + 1;

     ## century and decade from year
     my ($cc,$dec) = ($yyyy =~ m/(-?\d{1,2})(\d\d)/);
     my $ccplus = $cc + 1;
     my $ccplusrev = $ccplus * -1;
     my $ccminus = $cc - 1;

     ## 07 => 7
     (my $ccx = $cc ) =~ s/^0//;

     my $ccxrev = $ccx * -1;
     ## x1 => x1st ; 2 => 2nd etc.
     my $ccth = DateRDFUtils::numeral2ordinal($ccxrev);

     ## debug mode: only print $yyy & $ccth
     if ($opt_d) {
        print "year=$yyyy  ccth=$ccth\n"; next YEAR;
     }

     my $output = <<"EOF";
      <rdf:Description rdf:about="https://vocabs.acdh.oeaw.ac.at/date/$cc">
        <rdf:type rdf:resource="https://vocabs.acdh.oeaw.ac.at/unit_of_time/century"/>
        <rdf:type rdf:resource="http://www.w3.org/2004/02/skos/core#Concept"/>
        <skos:inScheme rdf:resource="https://vocabs.acdh.oeaw.ac.at/date/conceptScheme"/>
        <skos:prefLabel xml:lang="en">$ccth century BC</skos:prefLabel>
        <rdfs:label xml:lang="en">$ccth century BC</rdfs:label>
        <rdfs:label rdf:datatype="xsd:date">${ccplus}99/${ccplus}00</rdfs:label>
        <skos:definition xml:lang="en">A century from ${ccplus}99 to ${ccplus}00 in ISO8601 (the Gregorian and proleptic Gregorian calendar). A century from ${ccxrev}00 BC to ${ccplusrev}01 BC. </skos:definition>
        <time:hasTRS rdf:resource="http://www.opengis.net/def/uom/ISO-8601/0/Gregorian"/>
        <skos:exactMatch rdf:resource="http://dbpedia.org/resource/${ccth}_century_BC"/>
        <skos:exactMatch rdf:resource="http://yago-knowledge.org/resource/${ccth}_century_BC"/>
        <skos:exactMatch rdf:resource="https://vocabs.acdh.oeaw.ac.at/date/${ccplus}99%2F${ccplus}00"/>
        <!-- <skos:closeMatch rdf:resource="http://semium.org/time/${ccminus}xx"/> -->
        <skos:broader rdf:resource="https://vocabs.acdh.oeaw.ac.at/date/${onedigit}999%2F${onedigit}000"/>
        <time:intervalMeets rdf:resource="https://vocabs.acdh.oeaw.ac.at/date/$ccplus"/>
        <time:intervalMetBy rdf:resource="https://vocabs.acdh.oeaw.ac.at/date/$ccminus"/>
        <!--
        <skos:exactMatch rdf:resource="http://de.dbpedia.org/resource/20._Jahrhundert"/>
        <skos:exactMatch rdf:resource="http://www.wikidata.org/entity/Q6927"/>
        <skos:exactMatch rdf:resource="http://id.loc.gov/authorities/subjects/sh2002012476"/>
        -->
      </rdf:Description>
      <rdf:Description rdf:about="https://vocabs.acdh.oeaw.ac.at/date/${ccplus}99%2F${ccplus}00">
        <rdf:type rdf:resource="https://vocabs.acdh.oeaw.ac.at/unit_of_time/century"/>
        <rdf:type rdf:resource="http://www.w3.org/2004/02/skos/core#Concept"/>
        <skos:inScheme rdf:resource="https://vocabs.acdh.oeaw.ac.at/date/conceptScheme"/>
        <skos:prefLabel xml:lang="en">$ccth century BC</skos:prefLabel>
        <rdfs:label xml:lang="en">$ccth century BC</rdfs:label>
        <rdfs:label rdf:datatype="xsd:date">${ccplus}99/${ccplus}00</rdfs:label>
        <skos:definition xml:lang="en">A century from ${ccplus}99 to ${ccplus}00 in ISO8601 (the Gregorian and proleptic Gregorian calendar). A century from ${ccxrev}00 BC to ${ccplusrev}01 BC. </skos:definition>
        <time:hasTRS rdf:resource="http://www.opengis.net/def/uom/ISO-8601/0/Gregorian"/>
        <skos:exactMatch rdf:resource="https://vocabs.acdh.oeaw.ac.at/date/$cc"/>
        <!-- <skos:closeMatch rdf:resource="http://semium.org/time/${ccminus}xx"/> -->
        <time:intervalMeets rdf:resource="https://vocabs.acdh.oeaw.ac.at/date/$ccplus"/>
        <time:intervalMetBy rdf:resource="https://vocabs.acdh.oeaw.ac.at/date/$ccminus"/>
      </rdf:Description>

EOF

  print "$output";

} ## for yyy


###
print $DateRDFUtils::rdfend unless ($opt_H);
