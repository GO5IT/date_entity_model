#!/usr/bin/perl

use warnings;
use strict;
use utf8;

use DateTime qw(:all);
use DateTime::Calendar::Julian qw(:all);
use DateRDFUtils;
use Getopt::Std;

my $DEFAULT_FROM = "1901-01-01";
my $DEFAULT_TO   = "2000-12-31";

our ($opt_h, $opt_l, $opt_t, $opt_H, $opt_f, $opt_d);
getopts('hl:Hdf:t:');

sub usage {
  print <<"EOF";
USAGE $0 (-h) (-l <LIMIT>) (-H) (-d) (-f <DATE_FROM>) (-t <DATE_TO>)

-f <DATE_FROM>  Start with this date
               Format: (-)YYYY-MM-DD
             ( DEFAULT: $DEFAULT_FROM )
-t <DATE_TO>   End  with this date
             ( DEFAULT: $DEFAULT_TO )

-l <LIMIT>   Process at most <LIMIT> days

-H           Do NOT print RDF-headerder

-d           Debug mode: print list of dates - and NO RDF

     e.g.

    -1500-01-01	Friday	julian:	-1500-01-15
    -1500-01-02	Saturday	julian:	-1500-01-16
    -1500-01-03	Sunday	julian:	-1500-01-1

-h           Print this message

EOF

}

if ($opt_h) {
  usage();
  exit;
}


my $datefrom    = $opt_f ? $opt_f : $DEFAULT_FROM;
my $datemax     = $opt_t ? $opt_t : $DEFAULT_TO;


## parse $datefrom
my ($year, $month, $day) = ($datefrom =~ m/^(-?\d{1,4})-(\d\d)-(\d\d)$/);
my $dt = DateTime->new( year => $year, month => $month, day => $day );

## parse $datemax
my ($yearmax, $monthmax, $daymax) = ($datemax =~ m/^(-?\d{1,4})-(\d\d)-(\d\d)$/);
my $dtmax = DateTime->new( year => $yearmax, month => $monthmax, day => $daymax );

### print header unless -H
print $DateRDFUtils::rdfstart unless ($opt_H || $opt_d);

###################
my $n = 0;
DAY: while ( DateTime->compare( $dt, $dtmax ) <= 0 ) {
   ## limit with -l ?
   last DAY if ( $opt_l && ($opt_l <= $n++) );
   my $dtjul = DateTime::Calendar::Julian->from_object( object => $dt );
   if ($opt_d) {
       print $dt->date() . "\t" . $dt->day_name() . "\tjulian:\t" . $dtjul->date() . "\n";
   } else {
      my $date    = $dt->date();
      my $wdaytxt = $dt->day_name();
      my $jdate   = $dtjul->date();
      ## derive all others automatically
      my ($yyyy, $mm, $dd) = ($date =~ m/^(-?\d\d\d\d)-(\d\d)-(\d\d)$/);

      ## mm to text
      my $mmtxt = DateRDFUtils::mm2txt($mm, "en");

      ## century and decade from year
      my ($cc,$dec) = ($yyyy =~ m/(-?\d\d)(\d\d)/);

      ## 07 => 7
      (my $ddx = $dd ) =~ s/^0//;
      ## x1 => x1st ; 2 => 2nd etc.
      my $ddth = DateRDFUtils::numeral2ordinal($ddx);

       ############################ fill TEMPLATE and print
      my $output =  << "EOF";
      <rdf:Description rdf:about="https://vocabs.acdh.oeaw.ac.at/date/$yyyy-$mm-$dd">
        <rdf:type rdf:resource="https://vocabs.acdh.oeaw.ac.at/unit_of_time/day"/>
        <rdf:type rdf:resource="http://www.w3.org/2004/02/skos/core#Concept"/>
        <skos:inScheme rdf:resource="https://vocabs.acdh.oeaw.ac.at/date/conceptScheme"/>
        <skos:prefLabel xml:lang="en">$yyyy-$mm-$dd</skos:prefLabel>
        <rdfs:label rdf:datatype="xsd:date">$yyyy-$mm-$dd</rdfs:label>
        <skos:altLabel xml:lang="en">$dd $mmtxt $yyyy</skos:altLabel>
        <skos:altLabel xml:lang="en">$dd-$mm-$yyyy</skos:altLabel>
        <skos:altLabel xml:lang="en">$dd/$mm/$yyyy</skos:altLabel>
        <skos:altLabel xml:lang="en">$dd/$mm/$yyyy</skos:altLabel>
        <skos:definition xml:lang="en">$ddth $mmtxt $yyyy in ISO8601 (the Gregorian and proleptic Gregorian calendar)</skos:definition>
        <time:hasTRS rdf:resource="http://www.opengis.net/def/uom/ISO-8601/0/Gregorian"/>
        <time:monthOfYear rdf:resource="http://www.w3.org/ns/time/gregorian/$mmtxt"/>
        <time:DayOfWeek rdf:resource="http://www.w3.org/ns/time/gregorian/$wdaytxt"/>
        <skos:closeMatch rdf:resource="https://vocabs.acdh.oeaw.ac.at/date/julian_calendar/$jdate"/>
        <skos:broader rdf:resource="https://vocabs.acdh.oeaw.ac.at/date/$yyyy-$mm"/>
      </rdf:Description>

      <rdf:Description rdf:about="https://vocabs.acdh.oeaw.ac.at/date/julian_calendar/$jdate">
      <skos:closeMatch rdf:resource="https://vocabs.acdh.oeaw.ac.at/date/$yyyy-$mm-$dd"/>
      </rdf:Description>

EOF

      print "$output";

   }
   $dt->add(days=>1);
}

###################
print $DateRDFUtils::rdfend unless ($opt_H || $opt_d);
