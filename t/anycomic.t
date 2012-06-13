#use Test::More tests => 2;

use Modern::Perl;
use FindBin;
use lib "$FindBin::Bin/../Lib";
use AnyComic;
use AnyComic::Site;
use AnyComic::Book;
use AnyComic::Period;
use utf8;
use open ':utf8', ':std';

my $app = AnyComic->new(home_dir => $FindBin::Bin . '/..');

=dis
my $site = $app->get_site('bengou.com');

if (my $result = $site->search('海贼')) {
    for my $item (@$result) {
        say $item->{name};
        say $item->{author};
        say $item->{last_update_period};
        say $item->{url};
        say '-' x 80;
    }
}
=cut
#    url  => 'http://www.bengou.com/080819/hzw0008081910/index.html',
#    url  => 'http://www.bengou.com/080819/hzw0008081910/1337784973603/1337784973603.html',


#my $book_url = 'http://www.bengou.com/080819/hzw0008081910/index.html'; 
#my $period_url = 'http://www.bengou.com/080819/hzw0008081910/1337784973603/1337784973603.html';
my $book_url = 'http://imanhua.com/comic/54/';
my $period_url = 'http://imanhua.com/comic/54/list_68635.html';

if (my $res = $app->check_url($period_url)) {
    say 'Book Name: ', $res->{book}->name;
    say 'Periods:';
=dis    
    for my $period (@{$res->{book}->periods}) {
        say $period->name;
    }
=cut

    my $period = $res->{book}->periods->[0];
    if ($period->parse) {
        for my $page (@{$period->pages}) {
            say $page->url;
            $page->download;
        }
    }
}
1;
