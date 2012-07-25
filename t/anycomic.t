#use Test::More tests => 2;

use Modern::Perl;
use FindBin;
use lib "$FindBin::Bin/../Lib";
use Mojo::IOLoop;
use AnyComic;
use AnyComic::Site;
use AnyComic::Book;
use AnyComic::Period;
use Mojo::Util qw/encode decode url_escape/;
use utf8;
use open ':utf8', ':std';

my $app = AnyComic->new(home_dir => $FindBin::Bin . '/..');
#
#my $site = $app->get_site('bengou.com');
my $site = $app->get_site('imanhua.com');
my $ua = Mojo::UserAgent->new(
    name => 'Mozilla/5.0 (Windows NT 5.1) Gecko/20100101 Firefox/12.0',
);
         
my $cb = sub {
    my $result = shift;
    if ($result) {
        for my $item (@$result) {
            say $item->name;
            say $item->cover;
            say $item->{author};
            say $item->{last_update_period};
            say $item->{url};
            say '-' x 80;
        }
    }
};

my $delay = Mojo::IOLoop->delay;

my @sites = @{$app->{sites}}; 

for my $site (@sites) {
    $site->search('海贼1', ua => $ua, cb => $cb, delay => $delay);
}

#$site->search('死神', ua => $ua, cb => $cb, delay => $delay);

#$ua->get('http://www.baidu.com', sub { say "get baidu"; });
#$ua->get('http://www.google.com', sub { say "get google"; });
$delay->wait unless Mojo::IOLoop->is_running;
say "?";
exit;
#
#if (my $result = $site->search('死神')) {
#    for my $item (@$result) {
#        say $item->name;
#        say $item->cover;
#        say $item->{author};
#        say $item->{last_update_period};
#        say $item->{url};
#        say '-' x 80;
#    }
#}
#exit;
#    url  => 'http://www.bengou.com/080819/hzw0008081910/index.html',
#    url  => 'http://www.bengou.com/080819/hzw0008081910/1337784973603/1337784973603.html',


#my $book_url = 'http://www.bengou.com/080819/hzw0008081910/index.html'; 
#my $period_url = 'http://www.bengou.com/080819/hzw0008081910/1337784973603/1337784973603.html';
#my $book_url = 'http://imanhua.com/comic/54/';
#my $period_url = 'http://imanhua.com/comic/54/list_68635.html';
#my $book_url = 'http://www.u17.com/comic/30152.html';
#my $period_url = 'http://www.u17.com/comic_show/c6134_m0_i50459.html';
#if (my $res = $app->check_url($book_url)) {
#    my $book = $res->{book};
#    $book->refresh;
##    $book->parsed(0);
##    $book->parse;
#    say $book->data_dir;
#    say $book->periods->[0]->data_dir;
#    say 'Book Name: ', $book->name;
#    say $book->author;
#    say 'Periods:';
=dis    
    for my $period (@{$res->{book}->periods}) {
        say $period->name;
    }
=cut
=dis
    my $period = $res->{book}->periods->[0];
    if ($period->parse) {
        for my $page (@{$period->pages}) {
#            say $page->url;
#            $page->download;
        }
    }
=cut
#}
#1;
