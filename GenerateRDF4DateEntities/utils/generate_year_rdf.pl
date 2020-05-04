#!/usr/bin/perl

use warnings;
use strict;
use utf8;

use DateTime qw(:all);
use DateTime::Calendar::Julian qw(:all);
use DateRDFUtils;
use Getopt::Std;

my $DEFAULT_FROM = "-3000-01-01";
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

###################
my $n = 0;
my $prevdate;
my $nextdate;
my $prevyear;
my $nextyear;

## get $datefrom - 1 for the FIRST day in the line... 
my $dtprev = $dt; 
$dtprev->add(years=>-1);
$prevdate = $dtprev->date();

## increment again!
$dt->add(years => 1);


DAY: while ( DateTime->compare( $dt, $dtmax ) <= 0 ) {
   ## limit with -l ?
   last DAY if ( $opt_l && ($opt_l <= $n++) );
      my $date    = $dt->date();
      #my $wdaytxt = $dt->day_name();
      #my $jdate   = $dtjul->date();
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
      $dt->add(years=>1);
      $nextdate = $dt->date();  
      
      ## increate next and previous year
      $nextyear = $nextdate;  
      my ($nextyyyy, $mm_unuse_next, $dd_unuse_next) = ($nextyear =~ m/^(-?\d\d\d\d)-(\d\d)-(\d\d)$/);
      $prevyear = $prevdate;
      my ($prevyyyy, $mm_unuse_prev, $dd_unuse_prev) = ($prevyear =~ m/^(-?\d\d\d\d)-(\d\d)-(\d\d)$/);

      my $semium = DateRDFUtils::year2semium($yyyy);

      # If 0 prefix is present in yyyyx (between -999 and 999 except 0000), show additional altLabel without 0 prefx
      my $prefix0_altlabel = "";
      if ($yyyy == 0000){
      }
      elsif ($yyyy < 1000 and $yyyy > 0000){
      	$prefix0_altlabel = "" . qq{<skos:altLabel xml:lang="en">$yyyyx</skos:altLabel>}
      }
      else{
      }

      # If $nosignyyyy is AD except 0000, show additional altLabel for Year
      my $year_altlabel = "";
      if ($yyyy <= 0000){
     	$year_altlabel = "" . qq{Year $nosignyyyyplus BC}      	
      }
      else {
      	$year_altlabel = "" . qq{Year $nosignyyyyx}
      }
        
      ## make an additional altLabel, depending on BC and AD:
      my $ddx_altlabel = ""; 
      if ($bcsign eq "-"){
          $ddx_altlabel = "" . qq{$nosignyyyyplus BC}
      }
      else { 
          $ddx_altlabel = "" . qq{AD $nosignyyyyx}  
      }

      # special skos:note for BC 1, AD 1, AD 1582, 
      my $skosnote = "";
      if ($yyyy == "-0045"){
      	$skosnote = "" . qq{Year 46 BC was the last year of the pre-Julian Roman calendar. At the time, it was known as the Year of the Consulship of Caesar and Lepidus (or, less frequently, year 708 Ab urbe condita). The denomination 46 BC for this year has been used since the early medieval period, when the Anno Domini calendar era became the prevalent method in Europe for naming years. This year marks the change from the pre-Julian Roman calendar to the Julian calendar. The Romans had to periodically add a leap month every few years to keep the calendar year in sync with the solar year but had missed a few with the chaos of the civil wars of the late republic. Julius Caesar added two extra leap months to recalibrate the calendar in preparation for his calendar reform, which went into effect in 45 BC. This year therefore had 445 days, and was nicknamed the annus confusionis ("year of confusion") and serves as the longest recorded year in human history. By default, Date Entity uses ISO8601 as proleptic Gregorian year. However, it is possible to add the Julian calendar and pre-Julain Roman calendar in the future.}
      }
      elsif ($yyyy == "-0044"){
      	$skosnote = "" . qq{Year 45 BC was either a common year starting on Thursday, Friday or Saturday or a leap year starting on Friday or Saturday (link will display the full calendar) (the sources differ, see leap year error for further information) and the first year of the Julian calendar and a leap year starting on Friday of the Proleptic Julian calendar. At the time, it was known as the Year of the Consulship of Caesar without Colleague (or, less frequently, year 709 Ab urbe condita). The denomination 45 BC for this year has been used since the early medieval period, when the Anno Domini calendar era became the prevalent method in Europe for naming years. By default, Date Entity uses ISO8601 as proleptic Gregorian year. However, it is possible to add the Julian calendar and pre-Julain Roman calendar in the future.}
      }
      elsif ($yyyy == "0000"){
      	$skosnote = "" . qq{The following year is 1 AD in the Julian calendar, which does not have a "year zero". However, the year zero may be present for other systems such as the Buddhist and Hindu calendars, and the astronomical year. "0000" is used for ISO8601 as proleptic Gregorian calendar, meaning 1 BC. therefore, it is used as a Date Entity by default. Similarly, the preceding year is 2 BC and is represented as "-0001". It is possible to add the Julian calendar and pre-Julain Roman calendar in the future.}
      }
      elsif ($yyyy == "0001"){
      	$skosnote = "" . qq{The preceding year is 1 BC in the Julian calendar, which does not have a "year zero". However, the year zero may be present for other systems such as the Buddhist and Hindu calendars, and the astronomical year. "0000" is used for ISO8601 as proleptic Gregorian calendar, meaning 1 BC. therefore, it is used as a Date Entity by default. It is possible to add the Julian calendar and pre-Julain Roman calendar in the future.}
      }
      elsif ($yyyy == "1582"){
       	$skosnote = "" . qq{This year saw the beginning of the Gregorian Calendar switch, when the Papal bull known as Inter gravissimas introduced the Gregorian calendar, adopted by Spain, Portugal, the Polish–Lithuanian Commonwealth and most of present-day Italy from the start. In these countries, the year continued as normal until Thursday, October 4. However, the next day became Friday, October 15 (like a common year starting on Friday), in those countries (France followed two months later, letting Sunday, December 9 be followed by Monday, December 20). Other countries continued using the Julian calendar, switching calendars in later years, and the complete conversion of the Gregorian calendar was not entirely done until 1929. Date Entity uses ISO8601 (the Gregorian and proleptic Gregorian calendar) by default. However, it is possible to add the Gregorian calendar, the Julian calendar, and the pre-Julain Roman calendar in the future.}
      }
      else{
      }

      # DBpedia and YAGO syntax
      my $dbpedia_yago = "";
      # If $yyyy is between AD 1 and AD 99, format is AD_1 and AD_999 (without prefix 0)
      # Problem about inconsistent disambiguity for mathematical numbers, years, and other possible concepts by Bpedia, Wikipedia, and YAGO
      # Problem about inconsistent HTTP redirect by DBpedia (about until AD:999), Wikipedia, and YAGO (about until AD_101), thus we follow the stricter YAGO
      if ($yyyy > 0000 and $yyyy < 102){
		    $dbpedia_yago = "" . qq{AD_${yyyyx}}
      }
      elsif ($yyyy <= 0000){
		    $dbpedia_yago = "" . qq{${nosignyyyyplus}_BC}
      }
      else{
      	$dbpedia_yago = "" . qq{$yyyyx}
      }

      ## skos:broader depending on AD and BC (attention suffix -xxxx9 needs to be different (e.g. 0000 (1 BC) -> -001, -0769 (770 BC) -> -077):
      my $decade = DateRDFUtils::year2decade($yyyy);
      my $decade_minus = $decade - 1;
      my $decade_minus3digit = sprintf("%+.3d", $decade_minus);
      if ($yyyy == "0000"){
          $decade = "" . qq{-000}
      }
      elsif ($yyyy =~ /-\d{3}9/){
          $decade = "" . qq{$decade_minus3digit}
      }
      elsif ($yyyy =~ /-\d{4}/){
          $decade = "" . qq{$decade}
      }
      else { 
          $decade = "" . qq{$decade}  
      } 
      
       ############################ fill TEMPLATE and print
      my $output =  << "EOF";
      <rdf:Description rdf:about="https://vocabs.acdh.oeaw.ac.at/date/$yyyy">
        <rdf:type rdf:resource="https://vocabs.acdh.oeaw.ac.at/unit_of_time/year"/>
        <rdf:type rdf:resource="http://www.w3.org/2004/02/skos/core#Concept"/>
        <skos:inScheme rdf:resource="https://vocabs.acdh.oeaw.ac.at/date/conceptScheme"/>
        <skos:prefLabel xml:lang="en">$yyyy</skos:prefLabel>
        <rdfs:label rdf:datatype="xsd:gYear">$yyyy</rdfs:label>
        ${prefix0_altlabel}
        <skos:altLabel xml:lang="en">${ddx_altlabel}</skos:altLabel>
        <skos:altLabel xml:lang="en">${year_altlabel}</skos:altLabel>
        <skos:definition xml:lang="en">$yyyy in ISO8601 (the Gregorian and proleptic Gregorian calendar). ${ddx_altlabel}.</skos:definition>
        <skos:note>${skosnote} With regard to Date Entity modelling, documentation should be consulted at https://vocabs.acdh.oeaw.ac.at/date/. It includes information about URI syntax, ISO8601 conventions, and data enrichment among others.</skos:note>
        <time:hasTRS rdf:resource="http://www.opengis.net/def/uom/ISO-8601/0/Gregorian"/>
 		    <skos:exactMatch rdf:resource="http://dbpedia.org/resource/${dbpedia_yago}"/>
      	<skos:exactMatch rdf:resource="http://yago-knowledge.org/resource/${dbpedia_yago}"/>
        <skos:exactMatch rdf:resource="http://semium.org/time/$yyyy"/>
        <skos:broader rdf:resource="http://semium.org/time/${semium}xx"/>
        <skos:broader rdf:resource="https://vocabs.acdh.oeaw.ac.at/date/$decade"/>
        <time:intervalMeets rdf:resource="https://vocabs.acdh.oeaw.ac.at/date/$nextyyyy"/>
        <time:intervalMetBy rdf:resource="https://vocabs.acdh.oeaw.ac.at/date/$prevyyyy"/>
      </rdf:Description>
EOF

      ## beautify $output -> remove empty lines!
      $output =~ s/\n\s+\n/\n/g; 

      print "$output\n";

      $prevdate = $date;  ## store current date as $prevdate

}

###################
print $DateRDFUtils::rdfend unless ($opt_H || $opt_d);