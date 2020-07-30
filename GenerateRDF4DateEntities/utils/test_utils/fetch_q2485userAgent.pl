#!/usr/bin/perl 

use strict;
use warnings;
use Getopt::Std;

#use DateRDFUtils;

use LWP::UserAgent       ();

our ($opt_h, $opt_d, $opt_i,$opt_o,$opt_l,$opt_u,$opt_t,$opt_p, $opt_a);
getopts('hdi:o:l:u:tpa:');


#'application/rdf+xml'

our $useragent = LWP::UserAgent->new;
        $useragent->default_header('Accept-Charset'  => 'utf-8');
        $useragent->default_header('Accept-Language' => "en");
        $useragent->default_header('Accept' => $opt_a );

my $response = $useragent->get($opt_u);
 
if ($response->is_success) {
    print "== SUCCESS ==\n";
    print $response->decoded_content;
}
else {
    print "== FAIL ==\n";
    die $response->status_line;
}


