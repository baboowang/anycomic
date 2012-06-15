package AnyComicApp::Utils;
use Modern::Perl;
use Mojo::Util qw/encode decode/;
use Exporter 'import';
our @EXPORT = qw/cutstr trim/;

sub cutstr {
    my ($str, $len) = @_;

    $str = encode('UTF-8', $str) if utf8::is_utf8($str);

    my $i = 0;
    my $wi = 0;
    my $new_str = '';
    my @chars = split //, $str;
    my $n = scalar @chars;
    while ($i < $n) {
        my $ord = ord($chars[$i]);
        given ($ord) {
            when ($_ > 224) {
                $new_str .= substr($str, $i, 3);
                $i += 3;
                $wi += 2;
            }
            when ($_ > 192) {
                $new_str .= substr($str, $i, 2);
                $i += 2;
                $wi += 2;
            }
            default {
                $new_str .= substr($str, $i, 1);
                $i += 1;
                $wi += 1;
            }
        }
        last if $wi >= $len;
    }

    unless ($wi < $len || ($wi == $len && $i == $n)) {
        $new_str =~ s/(?:[\x{00}-\x{ff}]{3}|.{2})$/.../;
    }

    return decode('UTF-8', $new_str);
}

sub trim {
    my ($str, $chars) = @_;

    return $str unless $str;

    $chars //= '\\s';
    $str =~ s/^[$chars]+|[$chars]+$//g;

    return $str;
}
1;
