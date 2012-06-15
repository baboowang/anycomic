package AnyComicApp::Index;
use Mojo::Base 'AnyComicApp::Controller';

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

    my $url = $self->param('url');
    my $page = int($self->param('page') || '1');
    my $kw = $self->param('kw');

    my $schema = $anycomic->get_schema; 
    
    my $cond = {};
    my $attrs = {
        join => 'book',
        rows => $data->{shelf_x_size} * $data->{shelf_y_size},
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

    my $books = [];
    for my $row ($rs->all) {
        my $book = $anycomic->get_book($row->book->url);
        push @$books, $book if $book;
    }
    $data->{books} = $books;
    $data->{custom_css} = $self->get_custom_shelf_style;

    $self->stash($data);

    $self->render($self->is_ajax ? 'component/shelf' : 'index');
}
1;
