use v5.14;
use warnings;
use strict;
use utf8;

use Getopt::Long;
use FindBin;
use lib "$FindBin::Bin/../lib";
use WWW::Scraper::F1;
use Data::Dumper qw(Dumper);

my $upcoming = 1;
my $top      = -1;
my $points   = '';

GetOptions(
    'upcoming!' => \$upcoming,
    'top:i'     => \$top,
    'points=s'  => \$points,
);

if ($upcoming){
   my $race_info = get_upcoming_race( ) ;
   say "$race_info->{city}, $race_info->{country}\n$race_info->{countdown}\n";
}

my $champ_info = get_top_championship( {length => $top, points => $points} );
foreach my $t (@$champ_info){
   say "$t->{pos}. $t->{driver}\t $t->{points}"; 
}
