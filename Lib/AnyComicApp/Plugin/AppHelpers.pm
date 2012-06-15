package AnyComicApp::Plugin::AppHelpers;
use Mojo::Base 'Mojolicious::Plugin';
use List::Util qw/min max/;

use constant {
    MIN_SHELF_X_SIZE => 2,
    MIN_SHELF_Y_SIZE => 2,
    DEFAULT_SHELF_X_SIZE => 4,
    DEFAULT_SHELF_Y_SIZE => 2,
    DEFAULT_BATCH_COUNT => 10,
    DEFAULT_WRAPPER_WIDTH => 950,
    DEFAULT_LEFT_WIDTH => 720,
    SHLEF_FLOOR_HEIGHT => 205,
    BOOK_SPACE_WIDTH => 158,
};

# "You're watching Futurama,
# #  the show that doesn't condone the cool crime of robbery."
sub register {
    my ($self, $app) = @_; 

    $app->helper(in_shelf => sub {
        my ($self, $book) = @_;

        return 1;
    });

    $app->helper(is_ajax => sub {
        my $h = shift->req->headers->header('X-Requested-With');
        
        return $h and $h eq 'XMLHttpRequest';
    });
    
    $app->helper(page_batch_count => sub {
        my ($self, $count) = @_;

        return $self->session('batch_count') || DEFAULT_BATCH_COUNT
            unless $count;

        $self->session(expires => time + 3600 * 24 * 365);
        $self->session(batch_count => $count);
    });

    $app->helper(shelf_x_size => sub {
        my ($self, $size) = @_;

        return $self->session('shelf_x_size') || DEFAULT_SHELF_X_SIZE
            unless $size;

        $self->session(expires => time + 3600 * 24 * 365);
        $self->session(shelf_x_size => max($size, MIN_SHELF_X_SIZE));
    });

    $app->helper(shelf_y_size => sub {
        my ($self, $size) = @_;

        return $self->session('shelf_y_size') || DEFAULT_SHELF_Y_SIZE 
            unless $size;

        $self->session(shelf_y_size => max($size, MIN_SHELF_Y_SIZE));
    });

    $app->helper(get_custom_shelf_style => sub {
        my ($self) = @_;

        my $xSize = max($self->shelf_x_size, MIN_SHELF_X_SIZE);
        my $ySize = max($self->shelf_y_size, MIN_SHELF_Y_SIZE);

        if ($xSize == DEFAULT_SHELF_X_SIZE && $ySize == DEFAULT_SHELF_Y_SIZE) {
            return '';
        }
            
        my $deltaWidth = ($xSize - DEFAULT_SHELF_X_SIZE) * BOOK_SPACE_WIDTH;
        my $wrapperWidth = DEFAULT_WRAPPER_WIDTH + $deltaWidth;
        my $leftWidth = DEFAULT_LEFT_WIDTH + $deltaWidth;
        my $shelfHeight = SHLEF_FLOOR_HEIGHT * $ySize;
            
        return "#wrapper{width:${wrapperWidth}px}#left{width:${leftWidth}px}#shelfs,#shelf-loading,.shelf{height:${shelfHeight}px}";
    });

    $app->helper(read_log => sub {
        my ($self) = @_;

        my @rows = $self->anycomic->get_schema->resultset('ReadLog')->search(undef, {
            order_by => {
                -desc => 'last_time',
            },
            rows => 10,
        });

        my @read_logs = ();
        for my $row (@rows) {
            my $book = $self->anycomic->get_book($row->book->url);
            next unless $book;
            my $period = $book->find_period($row->last_period_id);
            push @read_logs, $period;
        }

        return \@read_logs;
    });
}

1;
