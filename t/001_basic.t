use warnings;
use strict;

use FindBin;
use lib "$FindBin::Bin/../lib";
use WWW::Scraper::F1;

use Test::More 'no_plan';

BEGIN { use_ok('WWW::Scraper::F1') }

ok(get_upcoming_race(), 'something returned from get_upcoming');
ok(get_top_championship(), 'something returned from get_top');


like(get_upcoming_race(), qr/^\w+\s*\w+, \w+\n(\d{1,3} days)?(\d{1,2} hours)?.*$/, 'get_upcoming() pattern match');
like(get_top_championship({points => 'just', length => 5}) , qr/^(\d{0,3}\n){5}$/ , 'get_top(points => \'just\', top_length => 5) pattern match');

#for tomorow me,
#  lets make dist::zille make a Build.pl file so it will hopefully run its tests on windows

