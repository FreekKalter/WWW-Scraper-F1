use warnings;
use strict;

use FindBin;
use lib "$FindBin::Bin/../lib";
use WWW::Scraper::F1;

use Test::More 'no_plan';

BEGIN { use_ok('WWW::Scraper::F1') }

ok(ref(get_upcoming_race())      eq "HASH" , 'get_upcoming_race returned hash_ref');
ok(ref(get_top_championship())   eq "ARRAY", 'get_top_championship return array_ref');

my $top  = get_top_championship();
my $race = get_upcoming_race();

is(scalar @$top, 5, 'top_championsip without arguments returned 5 elements');
is(scalar @{ get_top_championship( { length => 10 } ) }, 10 , 'top_championship with length option 10, returns 10 elements');

like($top->[0]{points} , qr/\d{0,3}/ , 'get_top_championship returns points in its hash');

like($race->{countdown} ,  qr/^(\d{1,3} days)?(\d{1,2} hours)?.*$/ , 'upcoming race countdown pattern match');

#like(get_upcoming_race(), qr/^\w+\s*\w+, \w+\n(\d{1,3} days)?(\d{1,2} hours)?.*$/, 'get_upcoming_race() pattern match');
#like(get_top_championship({points => 'just', length => 5}) , qr/^(\d{0,3}\n){5}$/ , 'get_top_championship({ points => \'just\', length => 5} ) pattern match');
#like(get_top_championship({points => 'just', length => 10}) , qr/^(\d{0,3}\n){10}$/ , 'get_top_championship({ points => \'just\', length => 10} ) pattern match');

#for tomorow me,
#  lets make dist::zille make a Build.pl file so it will hopefully run its tests on windows

