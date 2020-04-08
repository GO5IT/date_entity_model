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
my $DEFAULT_TO   = "2100-01-01";

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
   # MONTH: foreach my $mm ( qw(01 02 03 04 05 06 07 08 09 10 11 12) ) {
     ## limit with -l ?
     last YEAR if ( $opt_l && ($opt_l <= $n++) );

     my $decade = DateRDFUtils::year2decade($yyyy);
     my $semium = DateRDFUtils::year2semium($yyyy);
     my $onedigit = DateRDFUtils::year2onedigit($yyyy);

     ## century and decade from year
     my ($cc,$dec) = ($yyyy =~ m/(-?\d\d)(\d\d)/);

     ## 07 => 7
     (my $ccx = $cc ) =~ s/^0//;
     ## x1 => x1st ; 2 => 2nd etc.
     my $ccth = $ccx . "th";
     $ccth =~ s/1th/1st/;
     $ccth =~ s/2th/2nd/;
     $ccth =~ s/3th/3rd/;

     my $output = <<"EOF";
      <rdf:Description rdf:about="https://vocabs.acdh.oeaw.ac.at/date/$semium">
        <rdf:type rdf:resource="https://vocabs.acdh.oeaw.ac.at/unit_of_time/century"/>
        <rdf:type rdf:resource="http://www.w3.org/2004/02/skos/core#Concept"/>
        <skos:inScheme rdf:resource="https://vocabs.acdh.oeaw.ac.at/date/conceptScheme"/>
        <skos:prefLabel xml:lang="en">$ccth century</skos:prefLabel>
        <rdfs:label xml:lang="en">$ccth century</rdfs:label>
        <rdfs:label rdf:datatype="xsd:date">${cc}00/${cc}99</rdfs:label>
        <skos:definition xml:lang="en">A century from ${cc}00 to ${cc}99 in ISO8601 (the Gregorian and proleptic Gregorian calendar)</skos:definition>
        <time:hasTRS rdf:resource="http://www.opengis.net/def/uom/ISO-8601/0/Gregorian"/>
        <skos:exactMatch rdf:resource="http://dbpedia.org/resource/${ccth}_century"/>
        <skos:exactMatch rdf:resource="http://yago-knowledge.org/resource/${ccth}_century"/>

        <rdf:Description rdf:about="https://vocabs.acdh.oeaw.ac.at/date/1001%2F2000">
          <rdf:type rdf:resource="https://vocabs.acdh.oeaw.ac.at/unit_of_time/millennium"/>
          <rdf:type rdf:resource="http://www.w3.org/2004/02/skos/core#Concept"/>
          <skos:inScheme rdf:resource="https://vocabs.acdh.oeaw.ac.at/date/conceptScheme"/>
          <skos:prefLabel xml:lang="en">2nd Millennium</skos:prefLabel>
          <rdfs:label xml:lang="en">2nd Millennium</rdfs:label>
          <rdfs:label rdf:datatype="xsd:date">1001/2000</rdfs:label>
          <skos:definition xml:lang="en">A Millennium from 1001 to 2000 in ISO8601 (the Gregorian and proleptic Gregorian calendar)</skos:definition>
          <time:hasTRS rdf:resource="http://www.opengis.net/def/uom/ISO-8601/0/Gregorian"/>
          <skos:topConceptOf rdf:resource="https://vocabs.acdh.oeaw.ac.at/date/conceptScheme"/>
          <skos:exactMatch rdf:resource="http://dbpedia.org/resource/2nd_millennium"/>
          <skos:exactMatch rdf:resource="http://www.wikidata.org/entity/Q25860"/>
          <skos:exactMatch rdf:resource="http://babelnet.org/rdf/s02942509n"/>
          <skos:exactMatch rdf:resource="http://vocab.getty.edu/aat/300404551"/>
          <skos:exactMatch rdf:resource="http://semium.org/time/AD2xxx"/>
          <skos:narrower rdf:resource="https://vocabs.acdh.oeaw.ac.at/date/20"/>
          <time:intervalMeets rdf:resource="https://vocabs.acdh.oeaw.ac.at/date/2001%2F3000"/>
          <time:intervalMetBy rdf:resource="https://vocabs.acdh.oeaw.ac.at/date/0001%2F1000"/>
        </rdf:Description>

EOF

  print "$output";

} ## for yyy


###
print $DateRDFUtils::rdfend unless ($opt_H);
