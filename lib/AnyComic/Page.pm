package AnyComic::Page;
use Mojo::Base 'AnyComic::ImageBase';
use Mojo::URL;
use File::Basename;
use File::Path qw/make_path/;
use autodie;
use utf8;

has [qw/page_no url resource_url period local_path/]; 

has book => sub { shift->period->book };
has site => sub { shift->period->site };
has app  => sub { shift->period->app };
has id => sub { $_[0]->_get_url_key($_[0]->url) };
has autoload => 0;

sub url_name {
    my $self = shift;
    join ' ', $self->site->name, $self->book->name, 
        $self->period->name, '页' . $self->page_no; 
}

sub download {
    my $self = shift;

    return 1 if $self->downloaded;

    my $config = $self->site->config;
    my $page_config = $config->{page} || {};

    my $url_name = $self->url_name;

    my $url = $self->url;

    my $local_path = $self->period->data_dir . '/' . basename($self->resource_url || $url); 
    
    return 1 if -f $local_path && $self->_set_downloaded($local_path) && $self->save();

    my $headers = { referer => $self->period->url }; 
    my $resp = $self->_request_url($url, headers => $headers); 

    unless ($resp) {
        $self->log->error(qq{下载失败：$url_name});
        return;
    }

    $self->log->debug(qq{下载完成：$url_name. URL:$url});

    my $content;

    if (exists $page_config->{img}) {
        my $err;
        my $resource = $self->_filter($resp->dom, $page_config->{img}, $err);
        
        if ($err) {
            $self->log->error(qq{Page页面匹配失败：$url_name, $err. URL:$url});
        }

        if (ref $resource eq 'Mojo::DOM' and $resource->type eq 'img') {
            $resource = $resource->attrs('src');
        }
        
        if (not $resource or ref $resource) {
            $self->log->error(qq{Page页面过滤错误，输出结果只能为字符串或A的DOM对象});
            return;
        }

        $self->resource_url(my $resource_url = $resource);
        $local_path = $self->period->data_dir . '/' . basename($resource_url);

        return 1 if -f $local_path and $self->_set_downloaded($local_path);

        $headers->{referer} = $url;
        $resp = $self->_request_url($resource_url, headers => $headers);
        unless ($resp) {
            $self->log->error(qq{下载失败：$url_name});
            return;
        }

        $self->log->debug(qq{下载完成：$url_name});
    }

    $content = $resp->body;
    
    my $dir = dirname($local_path);
    make_path $dir unless -d $dir;

    open my $fh, '>:raw', $local_path;
    print $fh $content;
    close $fh;
    
    $self->log->debug(qq{保存$url_name：$local_path});
    $self->_set_downloaded($local_path);
    $self->save();

    return 1;
}


sub _on_save {
    my ($self, $data) = @_;
    
    return unless $self->local_path;

    my $image = {
        url => $self->resource_url || $self->url,
        local_path => $self->local_path,
    };
    $image->{id} = $self->_get_url_key($image->{url});
    
    return unless 
        $self->get_schema->resultset('Image')
             ->update_or_create($image, { key => 'primary' });

    $data->{image_id} = $image->{id};
    $data->{period_id} = $self->period->id;

    return 1;
}

sub _on_load {
    my ($self, $row) = @_;

    if (my $image = $row->image) {
        if (-f $image->local_path) {
            $self->_set_downloaded($image->local_path);
        }
    }
    
    my $url_name = $self->url_name;
    $self->log->debug(qq{从数据库中加载Page数据：$url_name});

    return 1;
}
1;
