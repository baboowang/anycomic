package AnyComicApp::Image;
use Mojo::Base 'AnyComicApp::Controller';

sub page {
    my $self = shift;
    my $anycomic = $self->anycomic;
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
}

sub cover {
    my $self = shift;
    my $anycomic = $self->anycomic;
    my $url = $self->param('url');
    my $res;

    $self->render_not_found unless 
        $url && ($res = $anycomic->check_url($url)) &&
        $res->{book}->cover &&
        $res->{book}->cover->download;
    
    #$self->render_static('/img/default.jpg');
    $self->render_static($res->{book}->cover->static_path);
}
1;
