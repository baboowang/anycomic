package AnyComicApp::Index;
use Mojo::Base 'AnyComicApp::Controller';
use AnyComic::Version;
use Mojo::UserAgent;
use Compress::Zlib;
use Mojo::IOLoop;
use Mojo::IOLoop::Delay;
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
    
    my $delay;

    if ($kw and (@$books == 0 or (@$books < $page_size and $search_outside))) {
        $self->render_later;

        $delay = Mojo::IOLoop->delay(sub{
            if (@$books > $page_size) {
                $data->{books} = [@{$books}[0..$page_size - 1]];
            }
            $self->stash($data);

            $self->render($self->is_ajax ? 'component/shelf' : 'index');
        });

        my $cb = sub {
            my $result = shift;
             
            return unless ref $result eq 'ARRAY';
    
            for my $book (@$result) {
                next if $self->in_shelf($book); 
                push @$books, $book;
            }
        };
        
        my @sites = shuffle @{$anycomic->{sites}}; 

        for my $site (@sites) {
            $site->search($kw, cb => $cb, delay => $delay);
        }

        $data->{show_search_outside} = 0;
        
        $delay->wait unless $delay->ioloop->is_running;

    }

    unless (exists $data->{show_search_outside}) {
        $data->{show_search_outside} = $search_outside ? 0 : 1;
    }

    $data->{books} = $books;
    $data->{pagesize} = $page_size;
    $data->{shelf_mid_x} = int($data->{shelf_x_size} / 2);
    $data->{custom_css} = $self->get_custom_shelf_style;
    $data->{app_version} = $AnyComic::Version::VERSION;

    return if $delay && $delay->{counter};

    $self->stash($data);

    $self->render($self->is_ajax ? 'component/shelf' : 'index');
}
1;
