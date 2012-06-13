package JavaScript::Unpack;
use JavaScript::V8;
use Exporter 'import';
our @EXPORT = qw/unpack_js/;

my $context = JavaScript::V8::Context->new;

sub unpack_js {
    my $js = shift;

    return $js unless $js =~ /eval\(+function\(/;

    $js = qq#
        var e_=eval, __unpacked_js;
        eval=function(v){ __unpacked_js = v };
        $js
        eval = e_;
        __unpacked_js;
    #;

    return $context->eval($js) || $js;
}

1;
