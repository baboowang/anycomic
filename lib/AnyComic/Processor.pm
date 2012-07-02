package AnyComic::Processor;
use Mojo::Base -base;
use Mojo::Util qw/encode decode/;
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

    my $text = $dom->all_text;

    $text = decode('UTF-8', $text) unless utf8::is_utf8($text); 

    return $text;
}

sub attr {
    my ($self, $dom, $attr) = @_;

    return $dom unless ref $dom eq 'Mojo::DOM';

    return $dom->attrs($attr);
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

sub filter {
    my ($self, $dom, $regexp) = @_;

    return $dom if $self->text($dom) ~~ qr/$regexp/i;
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

sub tpl {
    my ($self, $data_obj, $tpl) = @_;

    my $tpl_data = {
        %{$self->ref_obj->url_info || {}},
        '_' => '##_##'
    };
     
    $tpl =~ s/\{(\w+)\}/$tpl_data->{$1}/xsmieg;
    
    unless (ref $data_obj) {
        $tpl =~ s/##_##/$data_obj/g;
        return $tpl;
    }

    if (ref $data_obj eq 'ARRAY') {
        for my $_ (@$data_obj) {
            (my $item = $tpl) =~ s/##_##/$_/g;
            $_ = $item;
        }
    }

    return $data_obj;
}
1;
