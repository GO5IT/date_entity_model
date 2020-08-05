#!/usr/bin/perl

use strict;
use warnings;





############### for testing SQLite - store !







## testing SQlite Store for RDF::Trine
use RDF::Trine;
use RDF::Trine::Store::DBI::SQLite;

my $dbname = "sqlite_year.db";
my $store = RDF::Trine::Store->new({
                                     storetype => 'DBI',
                                     name      => '$modelname',
                                     dsn       => "dbi:SQLite:dbname=$dbname",
                                     username  => '',
                                     password  => ''
                                   });

###############
#use RDF::Trine::Store::DBI;
 
##my $user = 'me';
##my $pass = 'secret';
##my $modelname = 'mymodel';
## 
### First, construct a DBI connection to your database
##my $dsn = "DBI:mysql:database=perlrdf";
##my $user = ''; my $pass = '';
##my $dbh = DBI->connect( $dsn, $user, $pass );
## 
## Second, create a new Store object with the database connection
## and specifying (by name) which model in the Store you want to use
#my $store = RDF::Trine::Store::DBI->new( $modelname, $dbh );

# Finally, wrap the Store objec into a Model, and use it to access your data
my $model = RDF::Trine::Model->new($store);
print $model->size . " RDF statements in store\n";
