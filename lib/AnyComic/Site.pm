package AnyComic::Site;
use Mojo::Base 'AnyComic::Base';
use Mojo::Util qw/encode decode url_escape/;
use Mojo::URL;
use JSON;
use Scalar::Util 'weaken';
use AnyComic::Book;
use AnyComic::Schema;
use YAML::XS qw/DumpFile Dump/;
use utf8;

has [qw/app name domain config origin_config books _books_map _period_book_map/];

has id => sub { shift->domain };

sub is_book_url {
    my ($self, $url) = @_;
    my $config = $self->{config};

    my $valid = eval { exists $config->{book}{rule} ? $url ~~ /$config->{book}{rule}/i : undef; };

    if ($@) {
        my $site_name = $self->name;
        $self->log->error(qq{$site_name book rule 配置错误：$@});
    }

    return $valid;
}

sub is_period_url {
    my ($self, $url) = @_;
    my $config = $self->{config};

    my $valid = eval { exists $config->{period}{rule} ? $url ~~ /$config->{period}{rule}/i : undef; };

    if ($@) {
        my $site_name = $self->name;
        $self->log->error(qq{$site_name period rule 配置错误：$@});
    }

    return $valid;
}

sub add_book {
    my ($self, $url) = @_;

    my $site_name = $self->name;
    my $book_url = $url;
    my $period_url;

    if ($self->is_period_url($url)) {
        unless ($self->config->{period}{book}) {
            $period_url = $url;
            unless ($book_url = $self->try_get_book_url($url)) {
                $self->log->warn(qq{$site_name : 未配置Period URL转换Book URL的规则});
                return;
            }
        } else {

            unless (ref $self->config->{period}{book} eq 'CODE') {
                my $sub = eval 'sub { my $_ = shift; ' . $self->config->{period}{book} . '; $_}'; 
                if ($@) {
                    $self->log->error(qq{$site_name Period URL转换Book URL语法错误：$@});
                    return;
                }

                $self->config->{period}{book} = $sub;
            }

            $period_url = $url;
            $book_url = $self->config->{period}{book}->($period_url);

            unless ($book_url) {
                $self->log->error(qq{$site_name Period URL转换Book URL返回值错误});
                return;
            }
        }
    }

    unless ($self->is_book_url($book_url)) {
        $self->log->debug(qq{$book_url 不是一个Book URL});
        return;
    }

    $self->{_books_map} //= {};
    $self->{books} //= [];

    my $key = $self->_get_url_key($book_url);  
    my $book;

    unless (exists $self->{_books_map}{$key}) {
        $book = AnyComic::Book->new(url => $book_url, site => $self);
        weaken($book->{site});
        #$book->parse;

        my $len = push @{$self->{books}}, $book;
        $self->{_books_map}{$key} = $len - 1;
    } else {
        $book = $self->{books}[$self->{_books_map}{$key}];
    }
    
    my $res = { book => $book };

    if ($period_url) {
       my $period = $book->find_period($period_url); 
       $res->{period} = $period;
    }

    return $res;
}

sub remove_book {
    my ($self, $id) = @_;
    
    $id = $id->id if ref $id eq 'AnyComic::Book';

    unless (exists $self->{_books_map}{$id}) {
        return 1;
    }
    
    my $book = $self->get_schema->resultset('Book')->find($id);
    $book->delete if $book;
    undef $self->{books}[$self->{_books_map}{$id}];
    delete $self->{_books_map}{$id};

    return 1;
}

sub search {
    my ($self, $keyword) = @_;
    
    my $config = $self->config;
    my $site_name = $self->name;
    
    return unless exists $config->{search}{rule}
        && exists $config->{search}{items}
        && exists $config->{search}{props};

    my $search_url = $config->{search}{rule};
    my $err;
    my $encode_keyword;

    if (exists $config->{search}{keyword}) {
        unless (ref $config->{search}{keyword}) {
            $encode_keyword = $self->_excute_config_code(
                $config->{search}, 'keyword', $keyword, $err
            );

            if ($err) {
                $self->log->error(qq{$site_name 搜索关键词转换配置出错：$err});
                return;
            }
        }
    }

    unless ($encode_keyword) {
        my $kw = $keyword;
        if (ref $config->{search}{keyword} eq 'HASH' 
            && exists $config->{search}{keyword}{charset}
        ) {
            $kw = encode $config->{search}{keyword}{charset}, $kw; 
        }
        $encode_keyword = url_escape $kw;
    }

    $search_url =~ s/\{keyword\}/$encode_keyword/g;

    my $res = $self->_request_url($search_url);

    unless ($res) {
        $self->log->error(qq{$site_name 请求搜索链接失败});
        return;
    }
    
    my @items = $self->_filter($res->dom, $config->{search}{items}, $err);

    if ($err) {
        $self->log->error(qq{$site_name 搜索匹配失败, $err});
        return;
    }

    my $result = [];
    for my $item (@items) {
        my $item_info = {};
        
        for my $prop_name ('name', 'author', 'last_update_period', 'url') {
            if (exists $config->{search}{props}{$prop_name}) {
                my $prop_filter = $config->{search}{props}{$prop_name};
                my $prop = $self->_filter($item, $prop_filter, $err);

                if ($err) {
                    $self->log->error(qq{$site_name 搜索匹配属性 $prop_name 失败：$err});
                    continue;
                }
                
                my $prop_value = $prop;
                if (ref $prop eq 'Mojo::DOM') {
                    if ($prop->type eq 'img') {
                        $prop_value = $prop->attrs('src');
                    } elsif ($prop_name =~ /url/ && $prop->type eq 'a') {
                        $prop_value = $self->_abs_url($search_url, $prop->attrs('href')); 
                    } else {
                        $prop_value = $prop->all_text;
                    }
                }

                $item_info->{$prop_name} = $prop_value;
            }
        }

        if (%$item_info) {
            $item_info->{site} = $self;
            my $book = AnyComic::Book->new($item_info);
            weaken($book->{site});
            push @$result, $book;
        }
    }

    return $result;
}

sub try_get_book_url {
    my ($self, $period_url) = @_;

    $self->{_period_book_map} //= {};

    my $period_id = $self->_get_url_key($period_url);

    return $self->{_period_book_map}{$period_id}
        if exists $self->{_period_book_map}{$period_id};

    for my $book (@{$self->{books} || []}) {
        for my $period (@{$book->{periods} || []}) {
            if ($period_id eq $period->id) {
                $self->{_period_book_map}{$period_id} = $book->url;
                return $book->url;
            }
        }
    }
}

sub _on_save {
    my ($self, $data) = @_;

    $data->{id} = $data->{domain};
    $data->{config} = decode('UTF-8', Dump($self->origin_config));

    return 1;
}
1;
