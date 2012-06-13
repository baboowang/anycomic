package AnyComic::Processor;
use Mojo::Base -base;
use Mojo::Util qw/encode/;
use JSON;

has [qw/ref_obj/];

sub unpack {
    my ($self, $js) = @_; 

    my $unpacked_js = eval {
        use JavaScript::Unpack;
        unpack_js($js);
    };

    if ($@) {
        $self->ref_obj->log->error(qq{Processor[unpack_js]错误：$@});  
        return;
    }

    return $unpacked_js;
}

sub text {
    my ($self, $dom) = @_;

    return $dom unless ref $dom eq 'Mojo::DOM';

    return $dom->all_text;
}

sub json {
    my ($self, $json) = @_;

    my $obj = eval { decode_json(encode('UTF-8', $json)) };    

    if ($@) {
        $self->ref_obj->log->error(qq{Processor[json]错误：$@. $json});
        return;
    }

    return $obj;
}

sub key {
    my ($self, $obj, $key) = @_;
    
    unless (ref $obj ~~ /HASH|ARRAY/) {
        $self->ref_obj->log->error(qq{Processor[key]错误：操作对象必须是数组或HASH});
        return;
    }

    return $obj if $key ~~ undef;

    return ref $obj eq 'HASH' ? $obj->{$key} : $obj->[$key];
}

sub prefix {
    my ($self, $data_obj, $prefix) = @_;

    my $url_info = $self->ref_obj->url_info || {};

    $prefix =~ s/\[url_info\.(\w+)\]/$url_info->{$1}/xsmieg;
    
    unless (ref $data_obj) {
        return $prefix . $data_obj;
    }

    if (ref $data_obj eq 'ARRAY') {
        for my $_ (@$data_obj) {
            $_ = $prefix . $_;
        }
    }

    return $data_obj;
}
1;
