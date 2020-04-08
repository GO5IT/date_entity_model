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
USAGE $0 (-h) (-l <LIMIT>) (-H) (-f <DATE_FROM>) (-t <DATE_TO>)

Print RDF for all month starting with <DATE_FROM> up to <LIMIT> months or
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
   MONTH: foreach my $mm ( qw(01 02 03 04 05 06 07 08 09 10 11 12) ) {
     ## limit with -l ?
     last YEAR if ( $opt_l && ($opt_l <= $n++) );
     next MONTH if ($yyyy==$year && $mm < $month);
     last MONTH if ($yyyy==$yearmax && $mm > $monthmax);

     ## mm to text
     my $mmtxt = DateRDFUtils::mm2txt($mm, "en");

     ############################ fill TEMPLATE and print
    my $output =  << "EOF";
      <rdf:Description rdf:about="https://vocabs.acdh.oeaw.ac.at/date/$yyyy-$mm">
        <rdf:type rdf:resource="https://vocabs.acdh.oeaw.ac.at/unit_of_time/month"/>
        <rdf:type rdf:resource="http://www.w3.org/2004/02/skos/core#Concept"/>
        <skos:inScheme rdf:resource="https://vocabs.acdh.oeaw.ac.at/date/conceptScheme"/>
        <skos:prefLabel xml:lang="en">$yyyy-$mm</skos:prefLabel>
        <rdfs:label rdf:datatype="xsd:gYearMonth">$yyyy-$mm</rdfs:label>
        <skos:altfLabel xml:lang="en">$mmtxt $yyyy</skos:altfLabel>
        <skos:altfLabel xml:lang="en">$mm-$yyyy</skos:altfLabel>
        <skos:altfLabel xml:lang="en">$mm/$yyyy</skos:altfLabel>
        <skos:definition xml:lang="en">$mmtxt $yyyy in ISO8601 (the Gregorian and proleptic Gregorian calendar)</skos:definition>
        <time:hasTRS rdf:resource="http://www.opengis.net/def/uom/ISO-8601/0/Gregorian"/>
        <time:monthOfYear rdf:resource="http://www.w3.org/ns/time/gregorian/$mmtxt"/>
        <!--
         <skos:exactMatch rdf:resource="https://www.wikidata.org/entity/Q16630779"/>
        -->
        <skos:broader rdf:resource="https://vocabs.acdh.oeaw.ac.at/date/$yyyy"/>
      </rdf:Description>

      <!--
      <rdf:Description rdf:about="https://www.wikidata.org/entity/Q16630779">
        <skos:exactMatch rdf:resource="https://vocabs.acdh.oeaw.ac.at/date/$yyyy-$mm"/>
      </rdf:Description>
      -->

EOF

  print "$output";

} ## for mm
} ## for yyy


###
print $DateRDFUtils::rdfend unless ($opt_H);
