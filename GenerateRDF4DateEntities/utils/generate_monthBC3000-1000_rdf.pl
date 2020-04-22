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

my $DEFAULT_FROM = "-3000-01-01";
my $DEFAULT_TO   = "-1000-12-31";

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

     my $mmplus = $mm + 1;
     my $mmminus = $mm - 1;

     ## mm to text
     my $mmtxt = DateRDFUtils::mm2txt($mm, "en");

     #my $yyyyplus = $yyyy + 1;
     #my $yyyyminus = $yyyy - 1;

     # Reverse minus and plus to work on dates Before Christ
     my $yyyyrev = $yyyy * -1;
     my $yyyyrevplus = $yyyyrev + 1;
     my $yyyyrevminus = $yyyyrev - 1;

     #my $decade = DateRDFUtils::year2decade($yyyy);
     #my $semium = DateRDFUtils::year2semium($yyyy);
     #my $onedigit = DateRDFUtils::year2onedigit($yyyy);
     my $thirdone = DateRDFUtils::year2thirdone($yyyy);

     #my $thirdonerev = $thirdone * -1;

     # Reverse minus and plus to work on dates Before Christ
     #my $decaderev = $decade * -1;
     #my $decaderevplus = $decaderev + 1;
     #my $decaderevminus = $decaderev - 1;

     #my $onedigitrev = $onedigit * -1;
     #my $onedigitplus = $onedigit + 1;
     #my $onedigitrevplus = $onedigitrev + 1;


     ############################ fill TEMPLATE and print
    my $output =  << "EOF";
      <rdf:Description rdf:about="https://vocabs.acdh.oeaw.ac.at/date/-${yyyyrev}-$mm">
        <rdf:type rdf:resource="https://vocabs.acdh.oeaw.ac.at/unit_of_time/month"/>
        <rdf:type rdf:resource="http://www.w3.org/2004/02/skos/core#Concept"/>
        <skos:inScheme rdf:resource="https://vocabs.acdh.oeaw.ac.at/date/conceptScheme"/>
        <skos:prefLabel xml:lang="en">-${yyyyrev}-$mm</skos:prefLabel>
        <rdfs:label rdf:datatype="xsd:gYearMonth">-${yyyyrev}-$mm</rdfs:label>
        <skos:altLabel xml:lang="en">$mmtxt -${yyyyrev}</skos:altLabel>
        <skos:altLabel xml:lang="en">$mmtxt $yyyyrevplus BC</skos:altLabel>
        <skos:definition xml:lang="en">-${yyyyrev}-$mm in ISO8601 (the Gregorian and proleptic Gregorian calendar). $mmtxt $yyyyrevplus BC.</skos:definition>
        <skos:note>With regard to Date Entity modelling, documentation should be consulted at https://vocabs.acdh-dev.oeaw.ac.at/date/. It incldues information about URI syntax, ISO8601 conventions, and data enrichment among others.</skos:note>
        <time:hasTRS rdf:resource="http://www.opengis.net/def/uom/ISO-8601/0/Gregorian"/>
        <time:monthOfYear rdf:resource="http://www.w3.org/ns/time/gregorian/$mmtxt"/>
        <skos:broader rdf:resource="https://vocabs.acdh.oeaw.ac.at/date/-${yyyyrev}"/>
        <time:intervalMeets rdf:resource="https://vocabs.acdh.oeaw.ac.at/date/-$yyyyrev-0$mmplus"/>
        <time:intervalMetBy rdf:resource="https://vocabs.acdh.oeaw.ac.at/date/-$yyyyrev-0$mmminus"/>
      </rdf:Description>

EOF

  print "$output";

} ## for mm
} ## for yyy


###
print $DateRDFUtils::rdfend unless ($opt_H);
