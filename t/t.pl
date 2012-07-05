#!/usr/bin/perl
#use open ':utf8', ':std';

use Modern::Perl;
use Mojo::UserAgent;
use Mojo::Message::Response;
use Data::Dumper;
#use AnyComic::Config;
use FindBin;
use lib "$FindBin::Bin/../lib";
use AnyComic::Schema;
use File::stat;
use Mojo::URL;
use Mojo::DOM;
use JSON;
use Mojo::Util qw/decode encode/;
use Mojo::Collection qw/c/;
use File::Basename;
use AnyComic::Base;
use AnyComicApp;
use Cwd 'abs_path';
use utf8;
use YAML::XS qw/Dump LoadFile/;

my $c = LoadFile('config/sites/bengou.yml');

my $base = AnyComic::Base->new;

my $dom = Mojo::UserAgent->new->get('http://www.bengou.com/080819/00x0qdxdgts008081909/index.html')->res->dom;

for my $prop (keys %{$c->{book}{props}}) {
    my $prop_value = $base->_filter($dom, $c->{book}{props}{$prop});
    say "$prop: $prop_value";
}
exit;
my $s1 = q#setting.chapterInfo={"bookId":584,"bookName":"美食的俘虏","chapterId":54679,"chapterName":"142话","images":["imanhua_001_103130359.png","imanhua_002_103130375.png","imanhua_003_103130390.png","imanhua_004_103130406.png","imanhua_005_103130406.png","imanhua_006_103130406.png","imanhua_007_103130421.png","imanhua_008_103130421.png","imanhua_009_103130421.png","imanhua_010_103130437.png","imanhua_011_103130437.png","imanhua_012_103130437.png","imanhua_013_103130437.png","imanhua_014_103130453.png","imanhua_015_103130453.png","imanhua_016_103130453.png","imanhua_017_103130453.png","imanhua_018_103130484.png","imanhua_019_103130500.png"],"count":19};;imanhua.core.bind();#;

my $s = q#eval(function(p,a,c,k,e,d){e=function(c){return c};if(!''.replace(/^/,String)){while(c--)d[c]=k[c]||c;k=[function(e){return d[e]}];e=function(){return'\\w+'};c=1;};while(c--)if(k[c])p=p.replace(new RegExp('\\b'+e(c)+'\\b','g'),k[c]);return p;}('11.10={"9":12,"15":"14","13":8,"2":"3","1":["4.0","7.0","6.0","5.0","16.0","27.0","26.0","25.0","28.0","31.0","30.0","29.0","20.0","19.0","17.0","21.0","24.0","23.0"],"22":18};',10,32,'png|images|chapterName|189话|imanhua_001|imanhua_004|imanhua_003|imanhua_002|68660|bookId|chapterInfo|setting|584|chapterId|美食的俘虏|bookName|imanhua_005|imanhua_015||imanhua_014|imanhua_013|imanhua_016|count|imanhua_018|imanhua_017|imanhua_008|imanhua_007|imanhua_006|imanhua_009|imanhua_012|imanhua_011|imanhua_010'.split('|'),0,{}));imanhua.core.bind();#;

my $s2 = q#eval(function(p,a,c,k,e,d){e=function(c){return(c<a?"":e(parseInt(c/a)))+((c=c%a)>35?String.fromCharCode(c+29):c.toString(36))};if(!''.replace(/^/,String)){while(c--)d[e(c)]=k[c]||e(c);k=[function(e){return d[e]}];e=function(){return'\\w+'};c=1;};while(c--)if(k[c])p=p.replace(new RegExp('\\b'+e(c)+'\\b','g'),k[c]);return p;}('8.7={"9":b,"a":"6","1":2,"3":"5","4":["c.0","k.0","j.0","l.0","n.0","m.0","i.0","e.0","d.0","f.0"],"h":g};',24,24,'jpg|chapterId|46686|chapterName|images|336话|海贼王|chapterInfo|setting|bookId|bookName|55|imanhua_001_195546604|imanhua_009_195546761|imanhua_008_195546745|imanhua_010_195546808|10|count|imanhua_007_195546729|imanhua_003_195546667|imanhua_002_195546620|imanhua_004_195546683|imanhua_006_195546729|imanhua_005_195546714'.split('|'),0,{}));imanhua.core.bind();#;

my $s3 = q#eval(function(p,a,c,k,e,d){e=function(c){return c};if(!''.replace(/^/,String)){while(c--)d[c]=k[c]||c;k=[function(e){return d[e]}];e=function(){return'\\w+'};c=1;};while(c--)if(k[c])p=p.replace(new RegExp('\\b'+e(c)+'\\b','g'),k[c]);return p;}('12.13={"10":11,"16":"18","14":15,"2":"4","3":["5.0","8.0","9.0","6.0","7.0","19.0","30.0","29.0","28.0","31.0","34.0","33-32.0","27-22.0","21-20.0","23.1","26.1","25.1"],"24":17};',10,35,'png|jpg|chapterName|images|565话|imanhua_001|imanhua_004|imanhua_005|imanhua_002|imanhua_003|bookId|54|setting|chapterInfo|chapterId|61784|bookName||火影忍者|imanhua_006|017|imanhua_016|015|imanhua_018|count|imanhua_020|imanhua_019|imanhua_014|imanhua_009|imanhua_008|imanhua_007|imanhua_010|013|imanhua_012|imanhua_011'.split('|'),0,{}));#;

my $s4 = q#eval(function(p,a,c,k,e,d){e=function(c){return(c<a?"":e(parseInt(c/a)))+((c=c%a)>35?String.fromCharCode(c+29):c.toString(36))};if(!''.replace(/^/,String)){while(c--)d[e(c)]=k[c]||e(c);k=[function(e){return d[e]}];e=function(){return'\\w+'};c=1;};while(c--)if(k[c])p=p.replace(new RegExp('\\b'+e(c)+'\\b','g'),k[c]);return p;}('i.j={"k":f,"g":"h","l":p,"q":"r","m":["n.0","o.0","e.0","4.0","5.0","6.0","1.0","3.0","2.0","7.0","b.0","c.0","d.0","8.0","9.0","a.0","J.0","K.0","L.0","G.0","H.0","I.0","M.0","Q.0","R.0","S.0","N.0","O.0","P.0","F.0","v.0","w.0","x.0","s.0","t.0","u.0","y.0","C.0","D.0","E.0","z.0"],"A":B};',55,55,'jpg|imanhua_007|imanhua_009|imanhua_008|imanhua_004|imanhua_005|imanhua_006|imanhua_010|imanhua_014|imanhua_015|imanhua_016|imanhua_011|imanhua_012|imanhua_013|imanhua_003|3628|bookName|石黑龙传|setting|chapterInfo|bookId|chapterId|images|imanhua_001|imanhua_002|69043|chapterName|创刊号|imanhua_034|imanhua_035|imanhua_036|imanhua_031|imanhua_032|imanhua_033|imanhua_037|imanhua_041|count|41|imanhua_038|imanhua_039|imanhua_040|imanhua_030|imanhua_020|imanhua_021|imanhua_022|imanhua_017|imanhua_018|imanhua_019|imanhua_023|imanhua_027|imanhua_028|imanhua_029|imanhua_024|imanhua_025|imanhua_026'.split('|'),0,{}));#;

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
    $e =~ s/\+(?!\d)/./g;
say $e;
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
    state $chars = [0..9,'a'..'z'];
    my $num = shift;
    
    return $num > 35 ? base36(int($num / 36)) . $chars->[$num % 36] : $chars->[$num];
}

say unpack_js($s4);
__DATA__
my $ua = Mojo::UserAgent->new(
    name => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.7; rv:12.0) Gecko/20100101 Firefox/12.0',
);

$ua->max_redirects(2);

my $headers = { 
};
my $tx = $ua->get('http://www.u17.com/comic/2144.html', $headers);

my $a = '' . $tx->res->dom->find('dd.comic_info a[href*=i.u17.com]')->[0];

say decode('utf-8', $a);

