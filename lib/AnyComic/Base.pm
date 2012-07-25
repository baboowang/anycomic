package AnyComic::Base;
use Mojo::Base -base;
use Mojo::Log;
use Mojo::UserAgent;
use Mojo::Message::Response;
use Mojo::Util qw/encode decode/;
use Mojo::Collection;
use Compress::Zlib;
use Digest::MD5 'md5_hex';
use AnyComic;
use AnyComic::Schema;
use AnyComic::Processor;
use File::Path 'make_path';
use File::stat;
use JSON;
use utf8;
use autodie;

has app => sub { AnyComic->new };
has log => sub { shift->app->log };
has ua => sub { shift->app->ua };
has url_info => sub { {} };
has ['autoload', '_loaded'] => 0;

sub new {
    my $self = shift->SUPER::new(@_);

    return $self unless $self->autoload;

    $self->load; 

    return $self;
}

sub load {
    my $self = shift;

    return 0 if $self->_loaded;

    my ($table) = ref($self) =~ /(\w+)$/; 
    my $schema = $self->get_schema;    
    
    return 0 unless $schema;

    my $source = $schema->source($table);
    if ($source && $self->can('id') && $self->id) {
        if (my $row = $schema->resultset($table)->find($self->id)) {
            my @columns = $source->columns;
            for my $column (@columns) {
                if ($self->can($column) && ! $self->$column()) {
                    $self->$column($row->get_column($column));
                }
            }
            $self->_on_load($row);

            $self->_loaded(1);
        }
    }

    return 1;
}

sub get_schema {
    my $self = shift;
    
    return $self->app && $self->app->get_schema;
}

sub save {
    my ($self) = @_;
    my $schema = $self->get_schema;    
    
    my ($table) = ref($self) =~ /(\w+)$/; 

    my $source = $schema->source($table);

    my @columns = $source->columns;

    my $data = {};
    for my $column (@columns) {
        if ($self->{$column}) {
            $data->{$column} = $self->{$column};
        } elsif ($column eq 'id' && $self->{url}) {
            $data->{$column} = $self->_get_url_key($self->{url});
        }
    }

    return unless $self->_on_save($data);
    
    my $ret = $schema->resultset($table)->update_or_create($data, { key => 'primary' });

    $self->_loaded(1) if $ret;

    return $ret;
}

sub _on_save { 1 }
sub _on_load { 1 }

sub _request_url {
    my ($self, $url, %opts) = @_;

    my $headers = $opts{headers};
    my $nocache = $opts{nocache};
    my $ua = $self->ua;
    my $cb = $opts{cb};
    my $delay = $opts{delay};

    return unless $url;

    my $is_img = $url ~~ /\.(?:jpg|png|gif|jpeg|bmp)$/i;
    my $cache_file = $self->_get_url_key($url);
    my $cache_dir = $self->app->home_dir . '/tmp/cache/' . substr($cache_file, 0, 2); 
    # 可设置$AnyComic::CacheExpireTime变量，控制页面缓存文件失效的时间，单位为分钟，默认是1小时
    my $expire_time = time - $self->app->cache_expire_time * 60; 
    
    make_path $cache_dir unless -d $cache_dir;
    $cache_file = $cache_dir . '/' . $cache_file;
   
    if ( !$nocache and -f $cache_file and -s $cache_file and 
        ($is_img or stat($cache_file)->mtime > $expire_time)) 
    {
        $self->log->debug("使用缓存文件：$url");
        my $res = Mojo::Message::Response->new;
        $res->code(200);
        $res->default_charset('UTF-8');
        open my $fh, '<', $cache_file;
        my $content = do { local $/ = <$fh> };
        unless ($is_img) {
            $res->headers->content_type("text/html;charset=utf8");
        }
        $res->body($content);

        return $cb->($res) if $cb;

        return $res;
    }

    my $ua_cb = sub {
        my ($ua, $tx) = @_;
        
        $self->log->debug("回调：$url");

        unless ($tx->success) {
            $self->log->error("下载页面失败：$url");
            $delay->end if $delay;
            return;
        }
         
        my $res = $tx->res;
        my $content = $res->body;

        unless ($content) {
            $self->log->error("页面无内容：$url");
            $delay->end if $delay;
            return;
        }

        if ($res->content->charset) {
            my $charset = $res->content->charset;
            $charset = 'gbk' if $charset ~~ /gb2312/i;
            $content = decode $charset, $content;    
        } elsif (not $is_img) {
            my ($charset) = $content =~ /<meta[^>]+charset=([\w-]+)/i;  
            $charset = 'gbk' if $charset ~~ /gb2312/i;
            $charset ||= 'UTF-8';
            #$res->headers->add('Content-Type', "text/html;charset=$charset");
            $content = decode $charset, $content;
        }

        # 图片本身会保存在download目录，就不缓存了
        unless ($is_img) {
            $content = encode 'UTF-8', $content;
            open my $fh, '>', $cache_file;
            print $fh $content;
            close $fh;

            $res->headers->content_type("text/html;charset=utf8");
            $res->body($content);
        }

        if ($cb) {
            $cb->($res);
            $delay->end if $delay;
            return;
        }

        return $res;
    };

    if ($cb) {
        $self->log->debug("异步下载页面：$url");

        $delay->begin if $delay;

        $ua->get($url, $headers, $ua_cb);

        return;
    }

    $self->log->debug("下载页面：$url");

    my $tx = $ua->get($url, $headers);

    return $ua_cb->($ua, $tx);
}

sub _filter {
    my ($self, $dom, $filters) = @_;  

    my $err = \$_[3];

    $$err = '';

    $filters ||= [];
    
    $filters = [$filters] unless ref $filters;

    my @filters = @{$filters};
    my @res = ($dom);
    my $processor = AnyComic::Processor->new(ref_obj => $self);
    for my $filter (@filters) {
        $filter = { type => 'selector', value => $filter }
            unless ref $filter;
        
        #支持简写 filter_type => filter_value
        if (ref $filter eq 'HASH' and scalar keys %$filter == 1) {
            my ($filter_type) = keys %$filter;
            $filter = {
                'type'  => $filter_type,
                'value' => $filter->{$filter_type},
            };
        }

        unless (ref $filter eq 'HASH' and $filter->{value}) {
            $$err = '过滤配置格式错误';
            return;
        }

        my $filter_value = $filter->{value};
        my @new_res = ();

        given ($filter->{type}) {
            when ('selector') {
                for my $_ (@res) {
                    unless (ref $_ eq 'Mojo::DOM') {
                        $$err = qq{selecotr类型过滤的前置结果必须为Dom对象：$_};
                        return;
                    }
                    
                    #扩展选择器 :eq(index) :contains(all_text包含的字符中) 
                    my @selectors = split /(:eq\(\d+\)|:contains\([^\)]+\))/, $filter_value;

                    my @elems = ($_); 
                        
                    for my $selector (@selectors) {
                        last unless @elems;

                        my @new_elems = ();

                        given ($selector) {
                            when (/:eq\((\d+)\)/) {
                                push @new_elems, $elems[$1] if @elems > $1;          
                            }

                            when (/:contains\((.+)\)/) {
                                my $match_text = $1;
                                for my $elem (@elems) {
                                    push @new_elems, $elem if $processor->text($elem) ~~ qr/$match_text/i; 
                                }
                            }

                            default {
                                for my $elem (@elems) {
                                    $elem->find($selector)->each(sub{
                                        push @new_elems, shift;  
                                    });
                                }
                            }
                        }

                        @elems = @new_elems;
                    }

                    unless (@elems) {
                        $$err = qq{selector未筛选到结果：$filter_value};
                        return;
                    }
                    
                    @new_res = @elems;
                }
            }
            when ('regexp') {
                for my $_ (@res) {
                    $_ = "$_" if ref $_ eq 'Mojo::DOM';
                    $_ = decode('UTF-8', $_) unless utf8::is_utf8($_); 
                    my @ma = "$_" =~ m/$filter_value/xsmig; 
                    unless (@ma) {
                        $$err = qq{正则未匹配：$filter_value. \n 内容：$_};
                        return;
                    }
                    push @new_res, @ma;
                }
            }
            when ('script') {
                if (ref $filter_value ne 'CODE') {
                    my $code_ref = eval 'sub { my ($_, $url_info) = @_; my $data = $_;' . $filter_value . '; }';
                    if ($@) {
                        $$err = qq{过滤脚本错误：$@.\n$filter_value};
                        return;
                    }

                    $filter_value = $filter->{value} = $code_ref;
                }

                for my $_ (@res) {
                    my @ret = $filter_value->($_, $self->url_info);
                    push @new_res, @ret if @ret;
                }
            }
            when ('processor') {
                my @processors = ref $filter_value eq 'ARRAY'
                               ? @{$filter_value} : split(/\|/, $filter_value);

                for my $data_obj (@res) {
                    for my $_ (@processors) {
                        s/^\s+|\s+$//g;
                        my @params = split /\s+/;
                        my $method = shift @params;
                        unshift @params, $data_obj;
                        if ($processor->can($method)) {
                            $data_obj = $processor->$method(@params);
                            last unless $data_obj;
                        } else {
                            no strict 'refs';
                            
                            if (defined(&{$method})) {
                                $data_obj = \&{$method}->(@params);
                            } else {
                                $self->log->error(qq{Unknow Processor: $method});
                                return;
                            }
                        }
                    }
                    push @new_res, $data_obj if $data_obj;
                }
            }
            default {
                $$err = qq{错误的过滤类型：$_};
                return;
            }
        }

        @res = @new_res;
    }
    
    unless (@res) {
        $$err = qq{没有匹配到内容};
        return;
    }
    
    if (@res == 1 and ref $res[0] eq 'ARRAY') {
        @res = @{$res[0]};
    }

    return wantarray ? @res : $res[0];
}

sub _get_url_key {
    my (undef, $url) = @_;

    return md5_hex lc $url;
}

sub _get_url_info {
    my (undef, $url, $rule) = @_;

    my $info = {
        url => $url, 
    };

    return $info unless $rule and $url ~~ /$rule/i and keys %+;

    for my $key (keys %+) {
        $info->{$key} = $+{$key};
    }
    
    return $info;
}

sub _excute_config_code {
    my ($self, $config, $key, $params) = @_;

    my $err = \$_[4];
    
    $$err = '';

    return unless exists $config->{$key};
    
    unless (ref $config->{$key} eq 'CODE') {
        my $code = 'sub { ';

        if (ref $params eq 'HASH') {
            my $p_list = join ',', map { '$' . $_ } keys %{$params};
            $code .= "my ($p_list) = " . '@_;';
        } else {
            $code .= 'my $_=shift;';
        }

        $code .= $config->{$key} . ' }';
        
        my $code_ref = eval $code;

        if ($@) {
            $$err = $@;
            return;
        }

        $config->{$key} = $code_ref;
    }

    my @params;
    if (ref $params eq 'HASH') {
        @params = keys %$params;
    } else {
        @params = ($params);
    }

    my $ret = eval { $config->{$key}->(@params) };

    if ($@) {
        $$err = $@;
        return;
    }

    return $ret;
}

sub _abs_url {
    my ($self, $base_url, $url) = @_;

    return $url if $url ~~ /^http/i;

    if ($url ~~ /^\//) {
        $base_url =~ s#(?<!/)/(?!/).+$##;
    } else {
        $base_url =~ s#[^/]+$##;
    }

    return $base_url . $url;
}
1;
