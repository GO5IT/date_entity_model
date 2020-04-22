#!/usr/bin/perl

use warnings;
use strict;
use utf8;

use DateTime qw(:all);
use DateTime::Calendar::Julian qw(:all);
use DateRDFUtils;
use Getopt::Std;

my $DEFAULT_FROM = "2000-01-01";
my $DEFAULT_TO   = "3000-01-01";

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
my $prevdate;
my $nextdate;

## get $datefrom - 1 for the FIRST day in the line... 
my $dtprev = $dt; 
$dtprev->add(days=>-1);
$prevdate = $dtprev->date();
## increment again!
$dt->add(days => 1);


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

      ## separate $yyyy and its possible "-" 
      my $bcsign = "";
      my $nosignyyyy = $yyyy; 
      if ( $nosignyyyy =~ s/^-// or $nosignyyyy == "0000") {
         $bcsign = "-"
      }

      ### remove leading "0" in years
      ## 0001 => 1 , -0001 => -1
      (my $nosignyyyyx = $nosignyyyy) =~ s/^0{1,3}//;
      my $yyyyx;
      if ($bcsign) {
         $yyyyx = $bcsign . $nosignyyyyx;
      } else {
         $yyyyx = $nosignyyyyx;
      }

      ## for debugging / testing
      ## print "$yyyy - $yyyyx - $nosignyyyyx\n"; $dt->add(days => 1); next DAY;
      my $nosignyyyyplus = $nosignyyyy + 1;
      my $nosignyyyyminus = $nosignyyyy - 1;

      ## handle previous and next ...        
      ## increment date ...
      $dt->add(days=>1);
      $nextdate = $dt->date();  
      
      my $mm2digit=sprintf("%+.2d", $mm);
      #my $mm2digittake=~ s/^\+//;
      my $mm2digitplus = $mm2digit + 1;
      my $mm2digitminus = $mm2digit - 1;

      ## mm to text
      my $mmtxt = DateRDFUtils::mm2txt($mm, "en");

      my $dd2digit=sprintf("%+.2d", $dd);
      #my $dd2digittake=~ s/^\+//;
      my $dd2digitplus = $dd2digit + 1;
      my $dd2digitminus = $dd2digit - 1;

      ## century and decade from year

      ### remove leading "0" in days
      ## 07 => 7
      (my $ddx = $dd ) =~ s/^0//;
      my $ddx_altlabel = "\n\t\t\t\t";       
      ## x1 => x1st ; 2 => 2nd etc.
      my $ddth = DateRDFUtils::numeral2ordinal($ddx);

      ## make an additional altLabel and skos:definition, depending on BC and AD:
      if ($bcsign eq "-"){
        if ($dd =~ m/^0/) {
          $ddx_altlabel = "" . qq{<skos:altLabel xml:lang="en">$ddx $mmtxt $nosignyyyyplus BC</skos:altLabel>
      <skos:altLabel xml:lang="en">$ddth $mmtxt $nosignyyyyplus BC</skos:altLabel>}
        }
        else{
          $ddx_altlabel = "" . qq{<skos:altLabel xml:lang="en">$dd $mmtxt $nosignyyyyplus BC</skos:altLabel>
      <skos:altLabel xml:lang="en">$ddth $mmtxt $nosignyyyyplus BC</skos:altLabel>}   
        }

      }
      else { 
        if ($dd =~ m/^0/) {
          $ddx_altlabel = "" . qq{<skos:altLabel xml:lang="en">$ddx $mmtxt $nosignyyyyx</skos:altLabel>
      	<skos:altLabel xml:lang="en">$ddth $mmtxt $nosignyyyyx</skos:altLabel>}

        }
        else{
          $ddx_altlabel = "" . qq{<skos:altLabel xml:lang="en">$dd $mmtxt $nosignyyyyx</skos:altLabel>
      	<skos:altLabel xml:lang="en">$ddth $mmtxt $nosignyyyyx</skos:altLabel>}  
        }
      }

      my $ad_altlabel = "\n\t\t\t\t"; 
      if ($bcsign eq "-") {
      }
      else {
         $ad_altlabel = "" . qq{<skos:altLabel xml:lang="en">$bcsign$dd-$mm-$nosignyyyy</skos:altLabel>
        <skos:altLabel xml:lang="en">$bcsign$dd/$mm/$nosignyyyy</skos:altLabel>
        <skos:altLabel xml:lang="en">$bcsign$mm/$dd/$nosignyyyy</skos:altLabel>}
      }
      my $definition = "\n\t\t\t\t"; 
      if ($bcsign eq "-") {
        $definition = "" . qq{<skos:definition xml:lang="en">$date in ISO8601 (the Gregorian and proleptic Gregorian calendar). $ddth $mmtxt ${nosignyyyyplus} BC.</skos:definition>}
      }
      else {
        $definition = "" . qq{<skos:definition xml:lang="en">$date in ISO8601 (the Gregorian and proleptic Gregorian calendar). $ddth $mmtxt ${nosignyyyyx}.</skos:definition>}
      }

       ############################ fill TEMPLATE and print
      my $output =  << "EOF";
      <rdf:Description rdf:about="https://vocabs.acdh.oeaw.ac.at/date/$date">
        <rdf:type rdf:resource="https://vocabs.acdh.oeaw.ac.at/unit_of_time/day"/>
        <rdf:type rdf:resource="http://www.w3.org/2004/02/skos/core#Concept"/>
        <skos:inScheme rdf:resource="https://vocabs.acdh.oeaw.ac.at/date/conceptScheme"/>
        <skos:prefLabel xml:lang="en">$date</skos:prefLabel>
        <rdfs:label rdf:datatype="xsd:date">$yyyy-$mm-$dd</rdfs:label>
        ${ddx_altlabel}
        ${ad_altlabel}
        ${definition}
        <skos:note>With regard to Date Entity modelling, documentation should be consulted at https://vocabs.acdh-dev.oeaw.ac.at/date/. It includes information about URI syntax, ISO8601 conventions, and data enrichment among others.</skos:note>
        <time:hasTRS rdf:resource="http://www.opengis.net/def/uom/ISO-8601/0/Gregorian"/>
        <time:monthOfYear rdf:resource="http://www.w3.org/ns/time/gregorian/$mmtxt"/>
        <time:DayOfWeek rdf:resource="http://www.w3.org/ns/time/gregorian/$wdaytxt"/>
        <skos:closeMatch rdf:resource="https://vocabs.acdh.oeaw.ac.at/date/julian_calendar/$jdate"/>
        <skos:broader rdf:resource="https://vocabs.acdh.oeaw.ac.at/date/$yyyy-$mm"/>
        <time:intervalMeets rdf:resource="https://vocabs.acdh.oeaw.ac.at/date/$nextdate"/>
        <time:intervalMetBy rdf:resource="https://vocabs.acdh.oeaw.ac.at/date/$prevdate"/>    
      </rdf:Description>
EOF

      ## beautify $output -> remove empty lines!
      $output =~ s/\n\s+\n/\n/g; 

      print "$output\n";

      $prevdate = $date;  ## store current date as $prevdate
   }

}

###################
print $DateRDFUtils::rdfend unless ($opt_H || $opt_d);
