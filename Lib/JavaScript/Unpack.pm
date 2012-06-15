package JavaScript::Unpack;
#use JavaScript::V8;
use Exporter 'import';
our @EXPORT = qw/unpack_js/;

#my $context = JavaScript::V8::Context->new;

=dis
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
=cut 

sub unpack_js{
    my $s = shift; 
        
    my ($e) = $s =~ /eval\(function\(.+?\){e=function\(c\)\{([^}]+)\}/;

    return $s unless $e;

    my ($params) = $s =~ /\}\(('.+?')\.split\('\|'\)/;
    my ($code, $a, $c, $words)  = $params =~ /^'(.+?)',(\d+),(\d+),'(.+)'$/;
    
    $e =~ s/\ba\b/$a/g;
    $e =~ s/parseInt/int/g;
    $e =~ s/String\.fromCharCode/chr/g;
    $e =~ s/c\.toString\(36\)/base36\(c\)/g;
    $e =~ s/\bc\b/\$c/g;
    $e =~ s/\be\b/&\$pe/g; 
    $e =~ s/\+/./g;

    my $pe;
    eval('$pe = sub { my $c = shift; ' . $e . ' };');

    if ($@) {
        say $@;
    }

    my @words = split /\|/, $words;
    
    while($c--) {
        next if $words[$c] ~~ undef or $words[$c] eq '';
        my $word = $pe->($c);
        $code =~ s/\b$word\b/$words[$c]/ge;
    }

    return $code;
}

sub base36 {
    my $chars = [0..9,'a'..'z'];
    my $num = shift;
    
    return $num > 35 ? base36(int($num / 36)) . $chars->[$num % 36] : $chars->[$num];
}
1;
