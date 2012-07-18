package AnyComicApp::Index;
use Mojo::Base 'AnyComicApp::Controller';
use AnyComic::Version;
use List::Util qw/shuffle/;

sub index {
    my $self = shift;
    my $anycomic = $self->anycomic;
    my $data = {
        shelf_x_size => $self->shelf_x_size,
        shelf_y_size => $self->shelf_y_size,
        his_item => [],
        books => [],
        read_logs => $self->read_log,
    };
    my $search_outside = $self->param('outside');

    my $url = $self->param('url');
    my $page = int($self->param('page') || '1');
    my $kw = $self->param('kw');
    my $page_size = $data->{shelf_x_size} * $data->{shelf_y_size};
    my $schema = $anycomic->get_schema; 
    
    my $cond = {};
    my $attrs = {
        join => 'book',
        rows => $page_size,
        page => $page,
        order_by => {
            -desc => ['me.weight', 'me.add_time'],
        }
    };

    if ($kw) {
        $cond->{'book.name'} = { like => '%' . $kw . '%' };
    }
    
    my $rs = $schema->resultset('Shelf')->search($cond, $attrs);
    my $pager = $rs->pager;
    $data->{page} = $pager->current_page;
    $data->{total_pages} = $pager->last_page;
    $data->{kw} = $kw; 
    $data->{pagination} = $self->page_navigator($pager->current_page, $pager->last_page); 

    my $books = [];
    for my $row ($rs->all) {
        my $book = $anycomic->get_book($row->book->url);
        push @$books, $book if $book;
    }

    if ($kw and (@$books == 0 or (@$books < $page_size and $search_outside))) {
        my @sites = shuffle @{$anycomic->{sites}}; 

        SITE_LOOP : for my $site (@sites) {
            my $result = $site->search($kw);
            next unless $result;

            for my $book (@$result) {
                next if $self->in_shelf($book); 
                push @$books, $book;
                last SITE_LOOP if @$books >= $page_size;
            }
        }

        $data->{show_search_outside} = 0;
    }

    $data->{show_search_outside} = 1 unless exists $data->{show_search_outside};
    $data->{books} = $books;
    $data->{pagesize} = $page_size;
    $data->{shelf_mid_x} = int($data->{shelf_x_size} / 2);
    $data->{custom_css} = $self->get_custom_shelf_style;
    $data->{app_version} = $AnyComic::Version::VERSION;
    $self->stash($data);

    $self->render($self->is_ajax ? 'component/shelf' : 'index');
}
1;
