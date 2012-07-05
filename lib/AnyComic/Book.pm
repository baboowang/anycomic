package AnyComic::Book;
use Mojo::Base 'AnyComic::Base';
use Scalar::Util qw/weaken isweak/;
use AnyComic::Period;
use AnyComic::Book::Cover;
use AnyComic::Schema;
use Cwd 'abs_path';
use utf8;

has [qw/url name site _periods_map/];
has [qw/author intro area status cates update_time last_update_period last_refresh_time/];
has periods => sub { [] };
has app => sub { shift->site->app };
has id => sub { $_[0]->_get_url_key($_[0]->url) };
has parsed => 0;
has autoload => 1;
has data_dir => sub { 
    my $self = shift;
    return abs_path($self->app->home_dir) . '/download/' . substr($self->id, 0, 6) 
};
has is_period_asc => sub {
    return lc(shift->site->config->{book}{period_order} // 'desc') eq 'asc';
};

sub new {
    my $self = shift->SUPER::new(@_);

    if ($self->{cover}) {
        $self->cover($self->{cover});
    }

    return $self;
}

sub url_name { my $self = shift; join ' ', $self->site->name, $self->name || '' }

sub cover {
    my ($self, $cover) = @_;

    return $self->{cover} unless $cover;

    unless (ref $cover) {
        $cover = AnyComic::Book::Cover->new(
            url => $self->_abs_url($self->url, $cover),
            book => $self
        );
    }

    weaken($cover->{book}) unless isweak($cover->{book});

    $self->{cover} = $cover;

    return $self;
}

sub refresh {
    my $self = shift;
    
    my $origin_period_count = scalar @{$self->periods};
    my $origin_first_last_ids = '';

    if (@{$self->periods}) {
        $origin_first_last_ids =
            $self->periods->[0]->id . 
            $self->periods->[$#{$self->periods}]->id;
    }

    $self->parsed(0);
    $self->parse(1);

    my $new_period_count = scalar @{$self->periods};
    my $new_first_last_ids = '';

    if (@{$self->periods}) {
        $new_first_last_ids =
            $self->periods->[0]->id . 
            $self->periods->[$#{$self->periods}]->id;
    }
    
    $self->last_refresh_time(time);

    return not ($origin_period_count == $new_period_count &&
        $origin_first_last_ids eq $new_first_last_ids);
}

sub parse {
    my $self = shift;
    my $nocache = shift;

    return 1 if $self->parsed;

    my $url_name = $self->url_name;
    my $url = $self->url;
    my $config = $self->site->config; 

    my $resp;
    if ($nocache) {
        $resp = $self->_request_url_direct($url);
    } else {
        $resp = $self->_request_url($url);
    }
    
    unless ($resp) {
        $self->log->error(qq{下载Book页面失败：$url_name.});
        return;
    }
    
    $self->log->debug(qq{下载页面完成：$url_name});

    my $err = '';

    for my $prop ('name', 'author', 'intro', 'area', 'cates', 'update_time', 'status', 'cover') {
        my $prop_filters = $config->{book}{$prop} || $config->{book}{props}{$prop};
        next unless $prop_filters;
        my $err;
        my $res = $self->_filter($resp->dom, $prop_filters, $err);
        if ($res) {
            if (ref $res eq 'Mojo::DOM') {
                if ($res->type eq 'img') {
                    $res = $res->attrs('src');
                } else {
                    $res = $res->all_text;
                }
            }
            $self->$prop($res);
            if (ref $self->$prop && $self->$prop->can('save')) {
                $self->$prop->save();
            }
        } else {
            $self->log->warn(qq{分析Book属性${prop}错误：${err}});
        }
    }

    my @res = $self->_filter($resp->dom, $config->{book}{periods}, $err);
    
    if ($err) {
        $self->log->error(qq{Book页面匹配错误：$url_name, $err. URL:$url});
        return;
    }

    my @periods = ();
    $self->{_periods_map} = {};

    my $period_no = scalar @res;
    my $book_name_prefix = '^' . $self->name . '[/\\ _-]*';

    for my $item (@res) {
        my ($period_name, $period_url);

        if ($config->{book}{period_name}) {
            $period_name = $self->_filter($item, $config->{book}{period_name}, $err);
            if ($err) {
                $self->log->error(qq{Period名称获取错误：$url_name. $err});
            }
        } elsif (ref $item eq 'Mojo::DOM') {
            $period_name = $item->all_text;
            if ($err) {
                $self->log->error(qq{Period链接获取错误：$url_name. $err});
            }
        }

        if ($config->{book}{period_url}) {
            $period_url = $self->_filter($item, $config->{book}{period_url}, $err);
        } elsif (ref $item eq 'Mojo::DOM') {
            $period_url = $item->attrs('href');
        }

        unless ($period_name and $period_url) {
            $self->log->error(qq{未能匹配Period的名称和链接});
            return;
        }

        $period_url = $self->_abs_url($self->url, $period_url);
         
        $period_name =~ s/$book_name_prefix//;
        my $period = AnyComic::Period->new({
            name => $period_name,
            url => "$period_url", 
            period_no => $period_no--,
            book => $self
        });

        weaken($period->{book});

        $period->save;

        my $len = push @periods, $period;
        
        my $url_key = $self->_get_url_key("$period_url");
        $self->{_periods_map}{$url_key} = $len - 1;
    }

    $self->periods(\@periods);

        
    $self->save();
    $self->parsed(1);

    return 1;
}

sub find_period {
    my ($self, $id_or_url) = @_;
    
    return unless $self->{_periods_map};

    my $key = $id_or_url;
    if ($id_or_url ~~ /^http/i) {
        $key = $self->_get_url_key($id_or_url);
    }

    return undef unless exists $self->{_periods_map}{$key};

    my $period = $self->{periods}[$self->{_periods_map}{$key}];
    $period->load;

    return $period;
}

sub latest_period {
    my $self = shift;

    return undef unless @{$self->{periods}};

    my $period_index = $self->is_period_asc ? $#{$self->{periods}} : 0;
    my $period = $self->{periods}->[$period_index];
    $period->load;

    return $period;
}

sub next_period {
    my ($self, $period) = @_;
    $self->_period_offset($period, $self->is_period_asc ? 1 : -1);
}

sub prev_period {
    my ($self, $period) = @_;
    $self->_period_offset($period, $self->is_period_asc ? -1 : 1);
}

sub _period_offset {
    my ($self, $period, $offset) = @_;

    my $period_id = $period->id;
    return undef unless exists $self->{_periods_map}{$period_id};

    my $period_index = $self->{_periods_map}{$period_id} + $offset;
    return undef if $period_index < 0 || $period_index > $#{$self->{periods}};
    return $self->{periods}[$period_index];
}

sub _on_save {
    my ($self, $data) = @_;

    $data->{site_id} = $self->site->domain;

    return 1;
}

sub _on_load {
    my ($self, $row) = @_;
    
    my @periods = $row->periods->search(undef, { order_by => 'period_no DESC' });

    if (@periods) {
        my @period_objs = ();
        for my $period (@periods) {
            my $period_obj = AnyComic::Period->new({
                name => $period->name,
                url => $period->url, 
                period_no => $period->period_no,
                book => $self
            });

            weaken($period->{book});

            my $len = push @period_objs, $period_obj;
            
            $self->{_periods_map}{$period->id} = $len - 1;
        } 

        $self->periods(\@period_objs);
    }

    my $url_name = $self->url_name;
    $self->log->debug(qq{从数据库中加载Book数据：$url_name});
    
    if (my $cover = $row->cover) {
        $self->cover($cover->url); 
    }

    $self->parsed(1);

    return 1;
}
1;
