package AnyComicApp::Period;
use List::Util qw/min max/;
use Mojo::Base 'AnyComicApp::Controller';

sub index {
    my $self = shift;
    my $anycomic = $self->anycomic;
    my $url = $self->param('url');
    my $start = int($self->param('start') || '1') || 1;
    my $batch_count = int($self->param('batch') || '0');
    my $style = $self->param('style');

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
        pdf_plugin_active => $self->pdf_plugin_active,
    };
    
    $self->stash(%$data, %$res);

    $anycomic->get_schema->resultset('ReadLog')
        ->update_log($res->{book}->id, $res->{period}->id);

    my $styles = ['supersized'];

    if ($style && $style ~~ $styles) {
        $self->render('period_' . $style);
    } else {
        $self->render('period');
    }
}
1;
