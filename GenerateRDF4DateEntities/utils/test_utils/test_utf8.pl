#!/usr/bin/perl 
# This is an example from
# http://www.ahinea.com/en/tech/perl-unicode-struggle.html

use Encode;
my $ustring1 = "Hello \x{263A}!\n";  
my $ustring2 = <DATA>;
# $ustring2 = decode_utf8($ustring2);

print "$ustring1$ustring2";
__DATA__
Hello ☺!
