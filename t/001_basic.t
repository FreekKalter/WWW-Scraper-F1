use warnings;
use strict;

use FindBin;
use lib "$FindBin::Bin/../lib";
use WWW::Scraper::F1;

use Test::More 'no_plan';

BEGIN { use_ok('WWW::Scraper::F1') }

ok(get_upcoming_race(), 'something returned from get_upcoming_race');
ok(get_top_championship(), 'something returned from get_top_championship');


like(get_upcoming_race(), qr/^\w+\s*\w+, \w+\n(\d{1,3} days)?(\d{1,2} hours)?.*$/, 'get_upcoming_race() pattern match');
like(get_top_championship({points => 'just', length => 5}) , qr/^(\d{0,3}\n){5}$/ , 'get_top_championship({ points => \'just\', length => 5} ) pattern match');
like(get_top_championship({points => 'just', length => 10}) , qr/^(\d{0,3}\n){10}$/ , 'get_top_championship({ points => \'just\', length => 10} ) pattern match');

#for tomorow me,
#  lets make dist::zille make a Build.pl file so it will hopefully run its tests on windows

