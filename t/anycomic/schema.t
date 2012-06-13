use Test::More tests => 2;

use Modern::Perl;
use FindBin;
use lib "$FindBin::Bin/../../Lib";
use AnyComic::Schema;
use Data::Dumper;
use utf8;
use open ':utf8', ':std';

my $db_file = "$FindBin::Bin/../../database/anycomic.db";
my $schema = AnyComic::Schema->connect("dbi:SQLite:$db_file", '', '', {sqlite_unicode => 1});

my @sites = (['site1.com', 'site1.com', '站点1'], ['site2.com', 'site2.com', '站点2']);
ok ($schema->populate('Site', [
    [qw/id domain name/],
    @sites
]), 'Insert sites');

my @books = (
    ['book1', 'book1', '书名1', 'site1.com'],
    ['book2', 'book2', '书名2', 'site2.com']
);

ok ($schema->populate('Book', [
    [qw/id url name site_id/],
    @books
]), 'Insert books');


my $site = $schema->resultset('Site')->find('site1.com');

ok($site, 'Get a site');


my $book = $site->books->find('book1');

my %data = $book->get_columns;
my @columns = AnyComic::Schema->source('Site')->columns;
say Dumper(\@columns);

ok ($schema->resultset('Site')->delete_all, 'Delete sites');


