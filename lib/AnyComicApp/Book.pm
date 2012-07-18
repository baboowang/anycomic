package AnyComicApp::Book;
use Mojo::Base 'AnyComicApp::Controller';
use AnyComicApp::Utils;
use utf8;

sub index {
    my $self = shift;
    my $anycomic = $self->anycomic; 
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

    $self->stash({
        pdf_plugin_active => $self->pdf_plugin_active,
    });

    $self->stash($res)->render('book');
}

sub refresh {
    my $self = shift;
    my $anycomic = $self->anycomic; 
    my $url = $self->param('url');
    my $res; 

    unless ($url and ($res = $anycomic->check_url($url))) {
        return $self->fail("书链接不能识别: $url");
    }

    $self->ajax_result($res->{book}->refresh);
}

sub add {
    my $self = shift;
    my $anycomic = $self->anycomic;
    my $url = trim($self->param('url'));
    my $res; 

    unless ($url && ($res = $anycomic->check_url($url))) {
        return $self->fail(ERR_BOOK_URL, go => '/');
    }

    my $rs = $anycomic->get_schema->resultset('Shelf');
    
    if ($rs->find($res->{book}->id)) {
        #alreay exists, add flash message
        return $self->fail('书本已经添加过', go => '/');
    }
    
    my $ok = $res->{book}->parse; 
    
    if ($ok) { 
        $rs->create({
            book_id => $res->{book}->id,
            last_period_update_time => $res->{book}->update_time || ''
        });

        $self->done(msg => '添加书本成功《' . $res->{book}->name . '》');
    } else {
        $self->done(err_msg => '添加失败');
    }
}

sub suggest {
    my $self = shift;
    my $anycomic = $self->anycomic;
    my $keyword = $self->param('kw'); 

    my $res = {};

    if ($keyword) {
        $res->{word} = $keyword;
        $res->{result} = [];

        my @books = $anycomic->get_schema->resultset('Book')->search({
            name => { like => '%' . $keyword . '%' },
        }, {
            order_by => { -desc => 'update_time' },
            rows => 10,
        });

        for my $book (@books) {
            push @{$res->{result}}, {
                id => $book->id,
                name => $book->name,
                site_name => $book->site->name,
                url => $book->url,
            };
        }
    }

    $self->render_json($res);
}
1;
