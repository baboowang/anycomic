package AnyComic::ImageBase;
use Mojo::Base 'AnyComic::Base';
use Mojo::URL;
use File::Basename;
use File::Path qw/make_path/;
use autodie;
use utf8;

has [qw/url site local_path/]; 

has downloaded => 0;

has static_path => sub {
    my $self = shift;
    return unless $self->local_path;
    
    my $static_path = $self->local_path;
    
    $static_path =~ s/^.+?\bdownload\b//;
    return $static_path;
};

sub _download {
    my ($self, $refer_url, $url_name, $download_dir) = @_;

    return 1 if $self->downloaded;

    my $url = $self->url;
    my $local_path = $download_dir . '/' . basename($self->url);
    
    return 1 if -f $local_path && $self->_set_downloaded($local_path);

    my $headers = { Referer => $refer_url }; 
    my $resp = $self->_request_url($url, $headers); 

    unless ($resp) {
        $self->log->error(qq{下载图片失败：$url_name. $url});
        return;
    }

    $self->log->debug(qq{下载图片完成：$url_name});

    my $content = $resp->body;
    
    my $dir = dirname($local_path);
    make_path $dir unless -d $dir;

    open my $fh, '>:raw', $local_path;
    print $fh $content;
    close $fh;
    
    $self->log->debug(qq{保存图片$url_name：$local_path});
    $self->_set_downloaded($local_path);

    return 1;
}

sub _set_downloaded {
    my $self = shift;
    $self->downloaded(1);
    $self->local_path(shift);
    return 1;
}
1;
