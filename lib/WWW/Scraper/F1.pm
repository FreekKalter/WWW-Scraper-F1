package WWW::Scraper::F1;

use v5.14;
use warnings;

use parent qw(Exporter);
use HTML::TreeBuilder;
use LWP;
use DateTime::Format::Natural;
use DateTime::Format::Duration;
use Time::Piece;
use Storable;

our @EXPORT = qw(get_upcoming get_top);

sub get_upcoming {
    my $total_info = &get_info;
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

    $output = "$race_info->{city}, $race_info->{country}\n$until_race_time\n";
    return $output;
}

sub get_top {
    my %options = @_;
    my $total_info = &get_info;
    my $championship_table = $total_info->{'championship_info'};
    my ( $top_length, $points) = @_;
    my $output = '';
    #some defaults

    my $length =  $options{top_length} ? $options{top_length} : 5;
    my $points_display =  $options{points} ? $options{points} : 'yes';

    for ( my $i = 1 ; $i <= $length ; $i++ ) {
        given ($points_display) {
            when (/no/) {
                $output .= sprintf( "%d %-20s\n",
                    $i, $championship_table->[$i]->{'driver'} );
            }
            when (/just/) {
                $output .=
                  sprintf( "%d\n", $championship_table->[$i]->{'points'} );
            }
            default {    # default, print both tab separated
                $output .= sprintf( "%d %-20s %-3s\n",
                    $i,
                    $championship_table->[$i]->{'driver'},
                    $championship_table->[$i]->{'points'} );
            }
        }
    }
    return $output;
}

sub get_info {
    my $cache_name = "f1.cache";
    my ( $cache_content, $total_info );
    my $now = DateTime->now( time_zone => 'local' );
    if ( -e $cache_name ) {    #cache file exists
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
        say "race_info: No internet connection and no cache";
    }

    my $now = DateTime->now();
    my $championship_content =
      do_GET( "http://www.formula1.com/results/driver/" . $now->year );
    if ( !$championship_content ) {    #get failed (no internet connection)
        say "championship: No internet connection and no cache";
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

    $race_info->{city} =
      ucfirst lc $race_info->{city} =~ s/[\P{alpha}]//r;   #strip the html gunk, by removing all Non-alpha chars
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

=head1 NAME

WWW::Scraper::F1 

=head1 SYNOPSIS   

Scrape info for upcoming race and current championship from formula1.com.
