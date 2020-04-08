#!/usr/bin/perl 

use Date::Calc qw(:all);

use warnings;
use strict;

#### enumerate dates.
#### WARNING: Date::Calc  projects the Gregorian Calendar back to year "0" but 
#### cannot handle any "negative" dates, i.e. B.C. 


#my $y=2020;
#my $is_lepayear = leap_year($y) ? "yes" : "no";   
#print "$y is leap_year year ? : $is_lepayear\n";
 
my $year = 1500;
my $month = 1;
my $day = 1;

while ($year < 2050) {
   my $canonical = Date_to_Days($year,$month,$day);
   ($year,$month,$day) = Add_Delta_Days($year,$month,$day, 1); 

    my $dow = Day_of_Week_to_Text(Day_of_Week($year,$month,$day));

    print "$day-$month-$year $dow\n";

}

