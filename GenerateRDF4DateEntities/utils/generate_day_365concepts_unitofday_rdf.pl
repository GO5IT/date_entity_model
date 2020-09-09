#!/usr/bin/perl -CSD
use warnings;
use strict;
use utf8;

use DateTime qw(:all);
use DateTime::Calendar::Julian qw(:all);
use DateRDFUtils;
use Getopt::Std;


## This script is tailored to generate Month-Day concepts (ca 365 concepts) for Unit of Time Entities 
## NOTE: Generation is not 100% automatic with this script. <skos:definiton> for February 29 is manually added. February 30 is manually added. Thus, <time:intervalMeets> and <time:intervalMetBy> are also manually modified for the surrounding days 
my $DEFAULT_FROM = "2000-01-01";
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

    -1500-01-01 Friday  julian: -1500-01-15
    -1500-01-02 Saturday  julian: -1500-01-16
    -1500-01-03 Sunday  julian: -1500-01-1

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

# Forward declaration
my $n = 0;
my $prevdate;
my $nextdate;
my $comparison;
my $nonleapyear_nth_dayofyear;
my $nth_dayofyearminusx;
my $nth_dayofyearminusth;
my $leapdate;
my $definition_thday;

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
      my $bcad_date = $dt->year_with_christian_era();
      my $month_name = $dt->month_name();
      my $quarter_name = $dt->quarter_name();
      my $wdaytxt = $dt->day_name();
      my $jdate   = $dtjul->date();
      my $nth_dayofyear = $dt->day_of_year();
      ## 07 => 7 and x1 => x1st ; 2 => 2nd etc. for nth day of year
      (my $nth_dayofyearx = $nth_dayofyear) =~ s/^0//;
      my $nth_dayofyearth = DateRDFUtils::numeral2ordinal($nth_dayofyearx);
      my $month_abbr = $dt->month_abbr();
      ## derive all others automatically
      my ($yyyy, $mm, $dd) = ($date =~ m/^(-?\d\d\d\d)-(\d\d)-(\d\d)$/);


      my ($prevyyyy, $prevmm, $prevdd) = ($prevdate =~ m/^(-?\d\d\d\d)-(\d\d)-(\d\d)$/);
      (my $prevddx = $prevdd ) =~ s/^0//;
      my $prevmmtxt = DateRDFUtils::mm2txt($prevmm, "en");

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
      
      my ($nextyyyy, $nextmm, $nextdd) = ($nextdate =~ m/^(-?\d\d\d\d)-(\d\d)-(\d\d)$/);
      (my $nextddx = $nextdd ) =~ s/^0//;
      my $nextmmtxt = DateRDFUtils::mm2txt($nextmm, "en");

      my $mm2digit=sprintf("%+.2d", $mm);
      (my $mmx = $mm) =~ s/^0//;
      my $mm2digitplus = $mm2digit + 1;
      my $mm2digitminus = $mm2digit - 1;

      ## mm to text
      my $mmtxt = DateRDFUtils::mm2txt($mm, "en");
      my $mmtxt_de = DateRDFUtils::mm2txt($mm, "de");

      my $dd2digit=sprintf("%+.2d", $dd);
      #my $dd2digittake=~ s/^\+//;
      my $dd2digitplus = $dd2digit + 1;
      my $dd2digitminus = $dd2digit - 1;

      ## century and decade from year

      ### remove leading "0" in days
      ## 07 => 7
      
      (my $ddx = $dd )  =~ s/^0//;
      my $ddplus = $dd + 1;
      my $ddminus = $dd - 1;
      (my $ddxplus = $ddplus ) =~ s/^0//;
      (my $ddxminus = $ddminus ) =~ s/^0//;

      my $ddx_altlabel = "\n\t\t\t\t";       
      ## x1 => x1st ; 2 => 2nd etc.
      my $ddth = DateRDFUtils::numeral2ordinal($ddx);

      
      #Rectify nth day of non leap year
      $nth_dayofyearminusth = "";
      # Set DateTime object to allow compare function below
      $leapdate = DateTime->new(
        year       => 2000,
        month      => 03,
        day        => 01,
      );
      $comparison = DateTime->compare($dt, $leapdate);
      # March 1 onward
      if ($comparison == 1){
        $nonleapyear_nth_dayofyear = $nth_dayofyear - 1;
        $nth_dayofyearminusth = DateRDFUtils::numeral2ordinal($nonleapyear_nth_dayofyear);
        $definition_thday = "" . qq{the $nth_dayofyearminusth day of the year (the $nth_dayofyearth in leap years)};
      }
      # Until (including) February 29
      else{
        $nonleapyear_nth_dayofyear = $nth_dayofyear;
        $nth_dayofyearminusth = DateRDFUtils::numeral2ordinal($nonleapyear_nth_dayofyear);
        $definition_thday = "" . qq{the $nth_dayofyearminusth day of the year};
      }

       ############################ fill TEMPLATE and print
      my $output =  << "EOF";
      <rdf:Description rdf:about="https://vocabs.acdh.oeaw.ac.at/unit_of_time/${mmtxt}_${ddx}">
        <rdfs:subClassOf rdf:resource="http://www.w3.org/2004/02/skos/core#Concept"/>
        <rdf:type rdf:resource="http://www.w3.org/2002/07/owl#Class"/>
        <rdf:type rdf:resource="http://www.w3.org/2004/02/skos/core#Concept"/>
        <skos:inScheme rdf:resource="https://vocabs.acdh.oeaw.ac.at/unit_of_time/conceptScheme"/>
        <skos:prefLabel xml:lang="en">${mmtxt} ${ddx}</skos:prefLabel>
        <rdfs:label xml:lang="en">${mmtxt} ${ddx}</rdfs:label>
        <skos:altLabel xml:lang="en">${ddx} ${mmtxt}</skos:altLabel>
        <skos:altLabel xml:lang="en">$month_abbr $ddx</skos:altLabel>
        <skos:altLabel xml:lang="en">$ddx $month_abbr</skos:altLabel>
        <skos:altLabel xml:lang="en">${mm}-${dd}</skos:altLabel>
        <skos:altLabel xml:lang="en">${dd}-${mm}</skos:altLabel>
        <skos:altLabel xml:lang="en">${mmx}-${ddx}</skos:altLabel>
        <skos:altLabel xml:lang="en">${ddx}-${mmx}</skos:altLabel>
        <skos:altLabel xml:lang="en">${mm}/${dd}</skos:altLabel>
        <skos:altLabel xml:lang="en">${dd}/${mm}</skos:altLabel>
        <skos:altLabel xml:lang="en">${mmx}/${ddx}</skos:altLabel>
        <skos:altLabel xml:lang="en">${ddx}/${mmx}</skos:altLabel>
        <skos:altLabel xml:lang="en">${mm}\.${dd}</skos:altLabel>
        <skos:altLabel xml:lang="en">${dd}\.${mm}</skos:altLabel>
        <skos:altLabel xml:lang="en">${mmx}\.${ddx}</skos:altLabel>
        <skos:altLabel xml:lang="en">${ddx}\.${mmx}</skos:altLabel>
        <skos:definition xml:lang="en">${mmtxt} ${ddx} is $definition_thday in the Gregorian calendar.</skos:definition>
        <skos:exactMatch rdf:resource="http://dbpedia.org/resource/${mmtxt}_${ddx}"/>
        <skos:exactMatch rdf:resource="http://de.dbpedia.org/resource/${ddx}._${mmtxt_de}"/>
        <skos:exactMatch rdf:resource="http://yago-knowledge.org/resource/${mmtxt}_${ddx}"/>
        <skos:broader rdf:resource="https://vocabs.acdh.oeaw.ac.at/unit_of_time/${mmtxt}"/>
        <time:intervalMeets rdf:resource="https://vocabs.acdh.oeaw.ac.at/unit_of_time/${nextmmtxt}_${nextddx}"/>
        <time:intervalMetBy rdf:resource="https://vocabs.acdh.oeaw.ac.at/unit_of_time/${prevmmtxt}_${prevddx}"/>
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

