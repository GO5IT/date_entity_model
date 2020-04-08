#!/usr/bin/perl

use DateTime qw(:all);

use warnings;
use strict;

## DateTime also handles "negative" Dates, i.e. "B.C"

my $year = 1958;
my $month = 1;
my $day = 1;

my $dt = DateTime->new( year => $year, month => $month, day => $day );

while ($dt->year < 1959) {
   print $dt->date() . "\t" . $dt->day_name() . "\n";
   $dt->add(days=>1);
}
