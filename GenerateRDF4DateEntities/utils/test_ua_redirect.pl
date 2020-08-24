#!/usr/bin/perl 

use strict;
use warnings;

use LWP::UserAgent;
#use Date::RDFUtils;

use Getopt::Std;

my $MEDIATYPERDFXML = 'application/rdf+xml';
my $MEDIATYPEHTML = 'text/html';

my $dburlorig='http://dbpedia.org/resource/AD_2';
my $dbredirect='http://dbpedia.org/page/2'; 

our ($opt_h,$opt_r,$opt_a, $opt_u);
getopts('hr:a:u:');


if ($opt_h) {
 print <<"EOF";


USAGE: $0 (-h) -a ACCEPT -r MAXREDIRECT -u URL

-a  ACCEPT   -> "html" ($MEDIATYPEHTML)
                or 
                "rdf" ($MEDIATYPERDFXML)

-u  URL      -> "orig" ($dburlorig)
                or 
                "redirect" ($dbredirect) 

-r  MAXDDIRECT -> 0, 1, 2 ...

EOF

exit;
}

$opt_r = 0 unless $opt_r;
my $accept;
my $url; 

$opt_a = "" unless $opt_a;
if ($opt_a =~ /^h/) {
  $accept = $MEDIATYPEHTML;
} elsif ($opt_a =~ /^r/) {
  $accept = $MEDIATYPERDFXML;
} else {
  die "-a is not detected!\n";
}

$opt_u = "" unless $opt_u;
if ($opt_u =~ /^or/) {
  $url = $dburlorig;
} elsif ($opt_u =~ /^re/) {
  $url = $dbredirect;
} else {
  die "-u is not detected!\n";
}


our $useragent = LWP::UserAgent->new(
           protocols_allowed => [ 'http', 'https' ] 
);

  $useragent->default_header('Accept-Charset'  => 'utf-8');
  $useragent->default_header('Accept-Language' => "en");
  $useragent->default_header('Accept' => $accept );

  $useragent->max_redirect($opt_r);

my $response = $useragent->get($url);

if ($response->is_success) {
print $response->decoded_content;
} else {
  print "NO SUCCESS: ";
  print $response->status_line . "\n";
}

#orig: http://dbpedia.org/resource/AD_2
#wird im browser redirectet zu: http://dbpedia.org/page/2
