#!/usr/bin/perl -w
use Modern::Perl;
use Cwd 'abs_path';
use File::Basename;
use File::Spec::Functions 'catdir';
use Mojolicious::Lite;
use Mojo::Util qw/encode decode/;
use List::Util qw/min max/;
use lib dirname(__FILE__) . "/lib";
use AnyComic;
use AnyComic::Schema;
use utf8;

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

sub cutstr {
    my ($str, $len) = @_;

    $str = encode('UTF-8', $str) if utf8::is_utf8($str);

    my $i = 0;
    my $wi = 0;
    my $new_str = '';
    my @chars = split //, $str;
    my $n = scalar @chars;
    while ($i < $n) {
        my $ord = ord($chars[$i]);
        given ($ord) {
            when ($_ > 224) {
                $new_str .= substr($str, $i, 3);
                $i += 3;
                $wi += 2;
            }
            when ($_ > 192) {
                $new_str .= substr($str, $i, 2);
                $i += 2;
                $wi += 2;
            }
            default {
                $new_str .= substr($str, $i, 1);
                $i += 1;
                $wi += 1;
            }
        }
        last if $wi >= $len;
    }

    unless ($wi < $len || ($wi == $len && $i == $n)) {
        $new_str =~ s/(?:[\x{00}-\x{ff}]{3}|.{2})$/.../;
    }

    return decode('UTF-8', $new_str);
}

plugin xslate_renderer => {
    template_options => {
        function => {
            cutstr => sub {
                my ($len) = @_;

                return sub {
                    return cutstr(shift, $len);
                };
            },
        },
    },
};

my $base = dirname(__FILE__);
push @{app->renderer->paths}, catdir($base, 'templates'); 
push @{app->static->paths}, catdir($base, 'www'), catdir($base, 'download');

my $anycomic = AnyComic->new(home_dir => dirname(__FILE__));

app->secret(' -_-! ');

helper in_shelf => sub {
    my ($self, $book) = @_;

    return 1;
};

helper is_ajax => sub {
    my $h = shift->req->headers->header('X-Requested-With');
    
    return $h and $h eq 'XMLHttpRequest';
};

helper page_batch_count => sub {
    my ($self, $count) = @_;

    return $self->session('batch_count') || DEFAULT_BATCH_COUNT
        unless $count;

    $self->session(expires => time + 3600 * 24 * 365);
    $self->session(batch_count => $count);
};

helper shelf_x_size => sub {
    my ($self, $size) = @_;

    return $self->session('shelf_x_size') || DEFAULT_SHELF_X_SIZE
        unless $size;

    $self->session(expires => time + 3600 * 24 * 365);
    $self->session(shelf_x_size => max($size, MIN_SHELF_X_SIZE));
};

helper shelf_y_size => sub {
    my ($self, $size) = @_;

    return $self->session('shelf_y_size') || DEFAULT_SHELF_Y_SIZE 
        unless $size;

    $self->session(shelf_y_size => max($size, MIN_SHELF_Y_SIZE));
};

helper get_custom_shelf_style => sub {
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
};

helper read_log => sub {
    my ($self) = @_;

    my @rows = $anycomic->get_schema->resultset('ReadLog')->search(undef, {
        order_by => {
            -desc => 'last_time',
        },
        rows => 10,
    });

    my @read_logs = ();
    for my $row (@rows) {
        my $book = $anycomic->get_book($row->book->url);
        next unless $book;
        my $period = $book->find_period($row->last_period_id);
        push @read_logs, $period;
    }

    return \@read_logs;
};

get '/' => sub {
    my $self = shift;
    
    my $data = {
        shelf_x_size => $self->shelf_x_size,
        shelf_y_size => $self->shelf_y_size,
        his_item => [],
        books => [],
        read_logs => $self->read_log,
    };

    my $url = $self->param('url');
    my $page = int($self->param('page')) || 1;
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
};

any '/shelf/setting' => sub {
    my $self = shift;

    my $x = int($self->param('x')) || 4;
    my $y = int($self->param('y')) || 3;

    $self->shelf_x_size($x);
    $self->shelf_y_size($y);

    $self->redirect_to('/');
};

get '/add_book' => sub {
    my $self = shift;

    my $url = $self->param('url');
    my $res; 

    unless ($url && ($res = $anycomic->check_url($url))) {
        #erorr, add flash message
        return $self->redirect_to('/');
    }

    my $rs = $anycomic->get_schema->resultset('Shelf');
    
    if ($rs->find($res->{book}->id)) {
        #alreay exists, add flash message
        return $self->redirect_to('/');
    }
    
    $rs->create({
        book_id => $res->{book}->id,
        last_period_update_time => $res->{book}->update_time || ''
    });
    $res->{book}->parse; 

    $self->redirect_to('/');
};

get '/book' => sub {
    my $self = shift;
    
    my $data = {};
    my $url = $self->param('url');
    my $res; 

    unless ($url and ($res = $anycomic->check_url($url))) {
        return $self->redirect_to('/');        
    }

    my $book = $res->{book};

    if ($self->param('refresh')) {
        $book->refresh;

        return $self->redirect_to(
            $self->url_for('/book')->query(url => $book->url)
        );
    }
    
    $book->parse;
    
    if ( !$book->last_refresh_time || time - $book->last_refresh_time > 300 ) {
        $self->stash('check_refresh', 1);    
    }

    $self->stash($res);
};

get '/period' => sub {
    my $self = shift;
    my $url = $self->param('url');
    my $start = int($self->param('start') || '1') || 1;
    my $batch_count = int($self->param('batch'));
    my $res;
    
    if ($batch_count) {
        $self->page_batch_count($batch_count);
    } else {
        $batch_count = $self->page_batch_count;
    }

    return $self->render_not_found unless $url && ($res = $anycomic->check_url($url));
    return $self->redirect_to('/', url => $res->{book}->url) unless $res->{period}; 
    
    unless($res->{period}->parse) {
        $self->render_text('页面分析错误，详细请查看错误日志');
    }

    my $total = scalar @{$res->{period}->pages}; 
    my $end = min($total, $start + $batch_count - 1);

    my ($next_start, $next_end);
    
    if ($end < $total) {
        $next_start = $end + 1;
        $next_end = min($next_start + $batch_count - 1, $total);
    }

    my $data = {
        total => $total,
        start => $start,
        end => $end,
        batch_count => $batch_count,
        next_start => $next_start,
        next_end => $next_end,
        prev_period => $res->{book}->prev_period($res->{period}),
        next_period => $res->{book}->next_period($res->{period}),
    };
    
    $self->stash(%$data, %$res);

    $anycomic->get_schema->resultset('ReadLog')
        ->update_log($res->{book}->id, $res->{period}->id);
};

get '/page' => sub {
    my $self = shift;
    my $url = $self->param('url');
    my $page_index = int($self->param('i') || '1') || 1;
    my $res;
    
    $self->render_not_found unless 
        $url && $page_index && ($res = $anycomic->check_url($url)) && $res->{period};
    
    unless($res->{period}->parse) {
        $self->render_text('页面分析错误，详细请查看错误日志');
    }

    my $page = $res->{period}->get_page($page_index);

    $self->render_not_found unless $page and $page->download;
    
    if ($self->param('preload')) {
        $self->render_text('ok');
        return;
    }

    $self->render_static($page->static_path);
};

get '/cover' => sub {
    my $self = shift;
    my $url = $self->param('url');
    my $res;

    $self->render_not_found unless 
        $url && ($res = $anycomic->check_url($url)) &&
        $res->{book}->cover &&
        $res->{book}->cover->download;
    
    $self->render_static($res->{book}->cover->static_path);
};

get '/config';
# settings

get '/reload_config' => sub {
    ajax_output(shift, $anycomic->reload_config);
};

any '/refresh_book' => sub {
    my $self = shift;
    
    my $url = $self->param('url');
    my $res; 

    unless ($url and ($res = $anycomic->check_url($url))) {
        return ajax_output($self, 0);        
    }

    ajax_output($self, $res->{book}->refresh);    
};

sub ajax_output {
    my ($c, $res, $msg, $data) = @_;
    my $ret = {
        code => $res ? 0 : -1,
        msg => $msg // ($res ? '成功' : '失败')
    };
    
    $ret->{data} = $data if $data;
    
    $c->respond_to(
        json => { json => $ret },
        html => { text => $ret->{msg} }
    );
}

app->types->type(json => 'application/json; charset=utf-8;'); 

app->start;
