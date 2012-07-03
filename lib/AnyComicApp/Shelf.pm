package AnyComicApp::Shelf;
use Mojo::Base 'AnyComicApp::Controller';
use AnyComicApp::Utils;
use utf8;

sub setting {
    my $self = shift;

    my $x = int($self->param('x')) || 4;
    my $y = int($self->param('y')) || 3;

    $self->shelf_x_size($x);
    $self->shelf_y_size($y);

    $self->redirect_to('/');
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
    my $id = trim($self->param('id'));
    my $res; 

    my $book = $anycomic->get_book($id);
    unless ($book) {
        return $self->fail(ERR_BOOK_ID, go => '/');
    }

    my $rs = $anycomic->get_schema->resultset('Shelf');
    
    if ($rs->find($book->id)) {
        #alreay exists, add flash message
        return $self->fail('书本已经添加过', go => '/');
    }
    
    my $ok = $book->parse; 
    
    if ($ok) { 
        $rs->create({
            book_id => $id,
            last_period_update_time => $book->update_time || ''
        });

        $self->done(msg => '添加书本成功《' . $book->name . '》');
    } else {
        $self->done(err_msg => '添加失败');
    }
}
1;
