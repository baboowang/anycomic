package AnyComic::Period;
use Mojo::Base 'AnyComic::Base';
use Mojo::URL;
use Cwd 'abs_path';
use File::Basename;
use Scalar::Util 'weaken';
use AnyComic::Page;
use utf8;

has [qw/url name book period_no/];

has site => sub { shift->book->site };
has app => sub { shift->book->app };
has id => sub { $_[0]->_get_url_key($_[0]->url) };
has pages => sub { [] };
has parsed => 0;
has autoload => 0;
has data_dir => sub {
    my $self = shift;
    return $self->book->data_dir . '/' . substr($self->id, 0, 6);
};

sub url_name { my $self = shift; join ' ', $self->site->name, $self->book->name, $self->name }

sub parse {
    my $self = shift;

    return 1 if $self->parsed;

    my $url = $self->url;
    my $url_name = $self->url_name;
    my $config = $self->site->config;
     
    my $resp = $self->_request_url($url);
    
    unless ($resp) {
        $self->log->error(
            qq{下载Period页面失败：$url_name.}
        );
        return;
    }
    
    $self->log->debug(qq{下载页面完成：$url_name});

    $self->{url_info} = $self->_get_url_info($url, $config->{period}{rule});

    my $err = '';
    my @res = $self->_filter($resp->dom, $config->{period}{pages}, $err);
    
    if ($err) {
        $self->log->error(qq{Period页面匹配错误：$url_name, $err. URL:$url});
        return;
    }
    
    my @pages = ();
    my $page_no = 1;
    my %dom_attrs = ('img' => 'src', 'a' => 'href');
    for my $item (@res) {
        if (ref $item eq 'Mojo::DOM') {
            my $dom_type = $item->type;
            if (exists $dom_attrs{$dom_type}) {
                $item = $item->attrs($dom_attrs{$dom_type});
            } else {
                $self->log->error(qq{Period页面过滤错误，输出结果为无法解析的DOM类型： $dom_type});
                return;
            }
        }
        
        if (not $item or ref $item) {
            $self->log->error(qq{Period页面过滤错误，输出结果只能为字符串或是DOM对象});
            return;
        }

        $item = $self->_abs_url($self->url, $item);

        my $page = AnyComic::Page->new({
            url => "$item", 
            page_no => $page_no++,
            period => $self
        });

        weaken($page->{period});
        push @pages, $page;
    }

    $self->pages(\@pages);
    $self->parsed(1);
    $self->save();

    return 1;
}

sub get_page {
    my ($self, $page_no) = @_;
    
    my $page = $self->pages->[$page_no - 1];
    $page->load if $page;

    return $page;
}

sub _on_save {
    my ($self, $data) = @_;

    $data->{page_count} = scalar @{$self->pages};
    $data->{book_id} = $self->book->id;

    return 1;
}

sub _on_load {
    my ($self, $row) = @_;
    
    my @pages = $row->pages;

    return 1 unless @pages;

    my @page_objs = (); 
    for my $page (@pages) {
        my $page_obj = AnyComic::Page->new({
            url => $page->url,
            page_no => $page->page_no,
            period => $self,
        });
        
        weaken($page_obj->{period});
        $page_objs[$page->page_no - 1] = $page_obj;
    }
    
    $self->pages(\@page_objs);
    $self->parsed(1);

    my $url_name = $self->url_name;
    $self->log->debug(qq{从数据库中加载Period数据：$url_name});

    return 1;
}
1;
