#!/usr/bin/perl -CSD

use strict;
use warnings;
use Getopt::Std;

use LWP::UserAgent();

our ($opt_h, $opt_d, $opt_u, $opt_a);
getopts('hdu:a:');

my $DEFAULTACCEPT = 'application/rdf+xml';
my $accept = $opt_a ? $opt_a : $DEFAULTACCEPT;

sub usage {
  print <<"EOF";

USAGE $0 (-h) (-d) (-a <ACCEPT>) -u <URL> 

Fetch <URL> using perl's UserAgent::LWP and print result to <STDOUT>


-u <URL>    the <URL> which is fetched 
	    
-a <ACCEPT-HEADER>  
            DEFAULT: $DEFAULTACCEPT

-d           Debug mode: print excessive information to <STDOUT> 

-h           Print this message

EOF

}

if ($opt_h) {
  usage();
  exit;
}

#'application/rdf+xml'

our $useragent = LWP::UserAgent->new;
        $useragent->default_header('Accept-Charset'  => 'utf-8');
        $useragent->default_header('Accept-Language' => "en");
        $useragent->default_header('Accept' => $accept );

my $response = $useragent->get($opt_u);
 
if ($response->is_success) {
    print "== SUCCESS ==\n" if ($opt_d);
    print $response->decoded_content;
}
else {
    print "== FAIL !!! ==\n";
    die $response->status_line;
}


