package AnyComicApp::Pdf;
use Mojo::Base 'AnyComicApp::Controller';
use PDF::API2::Lite;
use IO::Scalar;
use Mojo::Util qw/encode decode/;
use utf8;

sub index {
    my $self = shift;
    my $anycomic = $self->anycomic;
    my $url = $self->param('url');

    my $res;
    
    return $self->render_not_found unless $url && ($res = $anycomic->check_url($url));
    return $self->redirect_to('/', url => $res->{book}->url) unless $res->{period}; 
    
    unless($res->{period}->parse) {
        $self->render_text('页面分析错误，详细请查看错误日志');
    }
    
    my $period = $res->{period};

    $self->render_later;

    my $pdf = PDF::API2::Lite->new;
    
    my @images = ();
    for my $page (@{$period->pages}) {
        unless ($page->download) {
            $self->render_text('图片下载失败');
            return;
        }

        my ($ext) = $page->local_path =~ /(\w+)$/;        
        $ext = lc $ext;
        $ext = 'jpeg' if $ext eq 'jpg';
        my $method = 'image_' . $ext; 
        if ($pdf->can($method)) {
            my $image = $pdf->$method($page->local_path);
            $pdf->page($image->width, $image->height);
            $pdf->image($image, 0, 0);
        }
    }

    my $pdf_content = $pdf->saveas('-');
    #my $fh = new IO::Scalar \$pdf_content;


    my $filename = $period->book->name . $period->name;
    $filename = encode('UTF-8', $filename);
    my $headers = Mojo::Headers->new();
    $headers->add( 'Content-Type', 'application/pdf');
    $headers->add( 'Content-Disposition', 'attachment;filename=' . $filename );
    $self->res->content->headers($headers);

    $self->render_data($pdf_content, format => 'pdf');
}
1;

