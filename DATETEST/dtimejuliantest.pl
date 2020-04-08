#!/usr/bin/perl

use DateTime qw(:all);
use DateTime::Calendar::Julian qw(:all);

use warnings;
use strict;

## DateTime also handles "negative" Dates, i.e. "B.C"

my $year = -1000;
my $month = 01;
my $day = 01;

my $dt = DateTime->new( year => $year, month => $month, day => $day );

while ($dt->year < -900) {
   my $dtjul = DateTime::Calendar::Julian->from_object( object => $dt );

   print $dt->date() . "\t" . $dt->day_name() . "\tjulian:\t" . $dtjul->date() . "\n";
   $dt->add(days=>1);
}
