package AnyComicApp::Config;
use Mojo::Base 'AnyComicApp::Controller';

sub index {
    my $self = shift;

    $self->render('config');
}

sub reload {
    my $self = shift;
    $self->ajax_result($self->anycomic->reload_config);
}
1;
