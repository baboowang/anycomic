#!/usr/bin/perl
use utf8;
use open ':utf8', ':std';

use Modern::Perl;
use Mojo::UserAgent;
use Mojo::Message::Response;
use Data::Dumper;
#use AnyComic::Config;
use YAML qw 'LoadFile';
use FindBin;
use lib "$FindBin::Bin/Lib";
use AnyComic::Schema;
use File::stat;
use Mojo::URL;
use Mojo::DOM;
use Mojo::Util qw/decode encode/;
use File::Basename;
use Cwd 'abs_path';

say Mojo::URL->new('http://a.com/c/g')->path;

package Test;
use Mojo::Base -base;

sub f {
    state $ok = 0;

    return if $ok;

    say 'ok';

    $ok = 1;
}
1;

package main;
my $ok1 = Test->new;
my $ok2 = Test->new;
$ok1->f();
$ok1->f();
$ok2->f();
__DATA__
my $ua = Mojo::UserAgent->new(
    name => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.7; rv:12.0) Gecko/20100101 Firefox/12.0',
);

$ua->max_redirects(2);

my $headers = { 
    referer => 'http://imanhua.com/comic/120/list_68643.html',
};
my $tx = $ua->get('http://t4.mangafiles.com/Files/Images/120/68643/imanhua_001.jpg', $headers);

use Data::Dumper;
say $tx->res->body;

