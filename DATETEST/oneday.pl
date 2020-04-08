#!/usr/bin/perl

#Documentation for PERL library https://metacpan.org/pod/Date::Calc
#Instruction to use this perl in Docker environment:
#docker-manage -e go-perl -a enter
#cd home/user/Perl-GenerateDates/DATETEST
#./oneday.pl

use Date::Calc qw(:all);

use warnings;
use strict;

#my $y=2020;
#my $is_lepayear = leap_year($y) ? "yes" : "no";
#print "$y is leap_year year ? : $is_lepayear\n";

my $year = 0001;
my $month = 12;
my $day0 = 12;
my $day = $day0-1;

my $n=18;
my $i=0;

while($i++ < $n) {

   ($year,$month,$day) = Add_Delta_Days($year,$month,$day, 1);

    my $dow = Day_of_Week_to_Text(Day_of_Week($year,$month,$day));

    print "$year-$month-$day $dow\n";

}
