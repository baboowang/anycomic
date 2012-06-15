package AnyComicApp::Book;
use Mojo::Base 'AnyComicApp::Controller';
use AnyComicApp::Utils;

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
        return $self->_ajax(0);
    }

    return $self->_ajax($res->{book}->refresh);
}

sub add {
    my $self = shift;
    my $anycomic = $self->anycomic;
    my $url = trim($self->param('url'));
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
}
1;
