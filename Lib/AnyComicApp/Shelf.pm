package AnyComicApp::Shelf;
use Mojo::Base 'AnyComic::Controller';

sub setting {
    my $self = shift;

    my $x = int($self->param('x')) || 4;
    my $y = int($self->param('y')) || 3;

    $self->shelf_x_size($x);
    $self->shelf_y_size($y);

    $self->redirect_to('/');
}
1;


