use v5.14;
use warnings;
use strict;

use Getopt::Long;
use FindBin;
use lib "$FindBin::Bin/../lib";
use WWW::Scraper::F1;

my $upcoming = 1;
my $top      = -1;
my $points   = '';

GetOptions(
    'upcoming!' => \$upcoming,
    'top:i'     => \$top,
    'points=s'  => \$points,
);

print get_upcoming_race( ) if ($upcoming);
print get_top_championship( {length => $top, points => $points} );

