package AnyComicApp::Controller;
use Mojo::Base 'Mojolicious::Controller';

has is_ajax => sub {
    my $h = shift->req->headers->header('X-Requested-With');
    
    return $h and $h eq 'XMLHttpRequest';
};

sub render {
    my $self = shift;
    my $popmsg = $self->flash('POPMSG');
    
    $self->stash('__msg', $popmsg) if $popmsg;

    return $self->SUPER::render(@_);
}

sub ajax_result {
    my ($self, $result) = @_;

    $self->is_ajax(1);
    
    $result ? $self->succ : $self->fail;
}

sub fail {
    my ($self, $msg, %data) = @_;
    if ($self->is_ajax) {
        my $ret = { 
            code => -1,
            msg  => $msg,
        };
    
        $self->render_json($ret);

        return 1;
    }
    
    $msg = {
        type => 'error',
        msg  => $msg
    };
    
    $self->flash('POPMSG', $msg);

    if ($data{go}) {
        return $self->redirect_to($data{go});
    }
}


sub succ {
    my ($self, $msg, %data) = @_;

    if ($self->is_ajax) {
        my $ret = {
            code => 0,
            msg  => $msg,
        };
        
        $ret->{data} = $data{data} if $data{data};
        $ret->{redirect_uri} = $data{go} if $data{go};

        $self->render_json($ret);

        return 1;
    }

    $msg = {
        type => 'succ',
        msg  => $msg,
    };

    $self->flash('POPMSG', $msg);

    if ($data{go}) {
        $self->redirect_to($data{go});
    }
}

sub done {
    my ($self, %data) = @_;
    my $redirect_uri = $data{go};

    unless ($redirect_uri) {
        if ($self->param('redirect_uri')) {
            $redirect_uri = $self->param('redirect_uri');
        } else {
            $redirect_uri = $self->req->headers->referrer || '/';
        }
    }

    if ($data{msg}) {
        return $self->succ($data{msg}, go => $redirect_uri);
    }

    $self->redirect_to($redirect_uri);
}
1;
