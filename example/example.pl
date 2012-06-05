use warnings;
use strict;
use utf8;

use FindBin;
use lib "$FindBin::Bin/../lib";
use WWW::Scraper::F1;
use Getopt::Long;

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
   print "$race_info->{city}, $race_info->{country}\n$race_info->{countdown}\n";
}

my $champ_info = get_top_championship( {length => $top} );

foreach my $t (@$champ_info){
   if($points eq "no"){
       print "$t->{pos}. $t->{driver}\n"; 
   }elsif($points eq "just"){
       print "$t->{points}\n";
   }else{
       print "$t->{pos}. $t->{driver}\t $t->{points}\n"; 
   }
}
