package WWW::Scraper::F1;

use v5.14;
use strict;
use warnings;
use warnings   qw(FATAL utf8);
use open       qw(:std :utf8);
use charnames  qw(:full :short);

use parent qw(Exporter);
use Unicode::Normalize;
use HTML::TreeBuilder;
use LWP;
use DateTime::Format::Natural;
use DateTime::Format::Duration;
use Time::Piece;
use Storable;
use Data::Dumper qw(Dumper);

our @EXPORT = qw(get_upcoming_race get_top_championship);

sub get_upcoming_race{
    my $options = shift;
    my $total_info = &get_info($options->{cache} // "1");

    my $race_info = $total_info->{'race_info'};
    my $output    = '';

    my $now = $race_info->{'now'};
    my $dt  = $race_info->{'time'};

    #convert datetime objects to Time::Piece objects, for actual day calculation (datetime object seem to want to convert 41 days to 1 month and some days)
    my $t1 =
      Time::Piece->strptime( $dt->strftime("%y %m %d %T"), "%y %m %d %T" );
    my $t2 =
      Time::Piece->strptime( $now->strftime("%y %m %d %T"), "%y %m  %d %T" );

    my $diff      = $t1 - $t2;
    my $diff_days = int $diff->days;    #use Time::Piece to calculate days left
    $diff = $dt - $now;

    #check if days or hours is 0 to prevent output like this ( 12 days 0 hours) this becomes just (12 days)
    my $until_race_time = sprintf( "%s%s",
        ( $diff_days > 0 )   ? "$diff_days days "       : "",
        ( $diff->hours > 0 ) ? "${\$diff->hours} hours" : "" );
    if ( $now > $dt ) {
        $until_race_time .= " ago";
    }
    $output = { 'city' => $race_info->{city},
                'country' => $race_info->{country},
                'time' => $dt->strftime("%d/%m/%y %T"),
                'countdown' => $until_race_time,
    };

    return $output;
}

sub get_top_championship{
    my $options = shift;
    $options->{points}  ||= "yes";
    $options->{length}  ||= 5;
    $options->{cache}   ||= "1";
    return if $options->{length} < 1;
    my $total_info = &get_info;
    my $championship_table = $total_info->{'championship_info'};

    my @ra = ();
    for ( my $i = 1 ; $i <= $options->{length} ; $i++ ) {
       my $tuple = { 'pos' => $i , 'driver' => $championship_table->[$i]->{'driver'} , 'points' =>  $championship_table->[$i]->{'points'} };
       push @ra, $tuple;
    }
    return \@ra;
}

sub get_info {
    my $cache = shift;
    my $cache_name = "f1.cache";
    my ( $cache_content, $total_info );
    my $now = DateTime->now( time_zone => 'local' );
    if ( $cache && -e $cache_name ) {    #cache file exists
        $cache_content = retrieve($cache_name);

        if ( $now > $cache_content->{'race_info'}->{'time'} ) {
           my $web_content = &build_from_internet();
           return undef if not $web_content;
           $total_info = &extract_info_from_web_content($web_content);
            store $total_info, $cache_name;
        }
        else {
            $total_info = $cache_content;
        }

    }
    else {    #get info from web, extract info and put it in a cacheble hash
       my $web_content = &build_from_internet();
       return undef if not $web_content;
       $total_info = &extract_info_from_web_content($web_content);
        store $total_info, $cache_name;
    }
    $total_info->{'race_info'}->{'now'} = $now;
    return $total_info;
}

sub build_from_internet {
    my %info              = ();
    my $race_info_content = do_GET("http://www.formula1.com/default.html");
    if ( !$race_info_content ) {    #get failed (no internet connection)
        print "race_info: No internet connection and no cache\n";
    }

    my $now = DateTime->now();
    my $championship_content =
      do_GET( "http://www.formula1.com/results/driver/" . $now->year );
    if ( !$championship_content ) {    #get failed (no internet connection)
        print "championship: No internet connection and no cache\n";
    }
    $info{'race_content'}         = $race_info_content;
    $info{'championship_content'} = $championship_content;
    return undef if(!$race_info_content || !$championship_content);
    return \%info;
}

sub extract_info_from_web_content {
    my $web_content = shift;
    my $total_info  = {};
    ################   extract time and place info from web_content
    my $race_info;

    #race time extraction
    foreach my $line ( split( '\n', $web_content->{'race_content'} ) ) {
        $line = NFD($line);
        if ( $line =~ m/grand_prix\[0\]\.sessions/ ) {
            $line =~ m/'Race','(.+)'/;
            my $parser = DateTime::Format::Natural->new( time_zone => 'GMT' );
            my $dt = $parser->parse_datetime( $parser->extract_datetime($1) );
            $dt->set_time_zone( DateTime::TimeZone->new( name => 'local' ) ) ;    #convert timezone to local
            $race_info->{time} = $dt;
        }
    }
    my $root = HTML::TreeBuilder->new;
    $root->parse( $web_content->{'race_content'} );
    $race_info->{country} =
      ucfirst
      lc $root->find_by_attribute( "id", "country_name" )->as_trimmed_text();
    $race_info->{city} =
      $root->find_by_attribute( "id", "city_name" )->as_trimmed_text();

    $race_info->{city} =~ s/[\P{alpha}]//;
    $race_info->{city} = ucfirst lc $race_info->{city};   #strip the html gunk, by removing all Non-alpha chars

    $total_info->{'race_info'} = $race_info;

    ################   extract championship info from web_content
    $root->parse( $web_content->{'championship_content'} );

    my $table = $root->look_down(
        "_tag"  => "table",
        "class" => "raceResults"
    );
    my @rows = $table->look_down( "_tag" => "tr" );
    for my $row (@rows) {
        my @columns = $row->look_down( "_tag", "td" );
        if (@columns) {
            $total_info->{'championship_info'}->[ $columns[0]->as_text() ]
              ->{'driver'} = $columns[1]->as_text();
            $total_info->{'championship_info'}->[ $columns[0]->as_text() ]
              ->{'points'} = $columns[4]->as_text();
        }
    }
    return $total_info;
}

sub do_GET {
    my $browser;
    $browser = LWP::UserAgent->new unless $browser;
    my $resp = $browser->get(@_);
    return ( $resp->content, $resp->status_line, $resp->is_success, $resp )
      if wantarray;
    return unless $resp->is_success;
    return $resp->content;
}
1;

__END__


=pod

=encoding utf8

=head1 NAME
                                        
WWW::Scraper::F1 - Use f1.com race data seamlessly in perl.

=head1 SYNOPSIS   

   use WWW::Scraper:F1;

   my $top      = get_top_championship( { length => 5 } );
   my $upcoming = get_upcoming_race();

=head1 FUNCTIONS


=head2 get_top_championship()

This functions retrieves the current championshiip.  it returns a reference to an array of hashes. By default it
returns the top 5 drivers like this.

   [
       { name Sebastian Vettel , points 55 , team Red Bull Racing }
       { name Fernando Alonso  , points 40 , team Ferrari }
   ]

You can specify options via a hash reference C<< get_top_chamionship( {length => 3} ) >>

=head2 get_upcoming_race()

This function returns a reference to hash. The hash elements contains information about the upcoming race.
The hash looks like this:

   {
     'country'    => 'Canada',
     'city'       => 'Montreal',
     'time'       => '10/06/12 20:00:00',
     'countdown'  => '7 days 21 hours'
   }

You can specify options via a hash refernce, C<get_upcoming_rac( { cache => 0 } )>
Available options:

=over 3

=item cache

Set this to 0, to not use the internal cache mechanism. This will disable reading form the cache file, it will still write the results of the call to it.

=back

=head1 INTERNALS

This module caches the results fetch from f1.com for futher use. Since the actual data only changes after a race, it only needs to fetch it again if the cache is older then the previous race. 

=head1 AUTHOR

Freek Kalter
freek@kalteronline.org
L<http://kalteronline.org>

=head1 COPYRIGHT

This module is distributed under the same lincense as perl5 itself.
