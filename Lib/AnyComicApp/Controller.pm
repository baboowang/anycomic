package AnyComicApp::Controller;
use Mojo::Base 'Mojolicious::Controller';

sub _ajax {
    my ($self, $res, $msg, $data) = @_;
    my $ret = {
        code => $res ? 0 : -1,
        msg => $msg // ($res ? '成功' : '失败')
    };
    
    $ret->{data} = $data if $data;
    
    $self->respond_to(
        json => { json => $ret },
        html => { text => $ret->{msg} }
    );
}
1;
