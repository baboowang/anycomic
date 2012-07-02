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

sub remove {
    my $self = shift;
    my $anycomic = $self->anycomic;
    my $id = trim($self->param('id'));
    my $res;
    
    my $rs = $anycomic->get_schema->resultset('Shelf');
    my $row = $rs->find($id);

    unless ($row) {
        return $self->fail('漫画不存在', go => '/');
    }

    my $book = $anycomic->get_book($id);
    $book->site->remove_book($book);

    $row->delete;

    $self->succ('漫画《' . $book->name . '》移出书架 ', go => '/');
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
1;
