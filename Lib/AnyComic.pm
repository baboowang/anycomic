package AnyComic;
use Mojo::Base 'AnyComic::Base';
use Mojo::URL;
use AnyComic::Site;
use Carp qw/carp croak/;
use Scalar::Util 'weaken';
use File::Spec::Functions 'catdir';
use YAML 'LoadFile';
use utf8;

has [qw/sites _domain_map/];

#页面缓存的失效时间，单位分钟
has cache_expire_time => 60;

has home_dir => '.';

has config_dir => sub { catdir(shift->home_dir, 'config') };

has site_config_dir => sub { catdir(shift->config_dir, 'sites') };

sub new {
    my $self = shift->SUPER::new(@_);

    $self->{sites} ||= [];
    $self->{_domain_map} ||= {};

    $self->load_config($self->site_config_dir)
        if -d $self->site_config_dir;

    return $self;
}

sub check_url {
    my ($self, $url) = @_;

    my $site = $self->get_site($url); 
    
    return unless $site;

    return $site->add_book($url);
}

sub get_book {
    my ($self, $book_id_or_url) = @_;
    
    if ($book_id_or_url !~ /^http/i) {
        my $row = $self->get_schema->resultset('Book')->find($book_id_or_url);
        return unless $row;
        $book_id_or_url = $row->url;
    }

    my $res = $self->check_url($book_id_or_url);

    return $res && $res->{book};
}

sub get_schema {
    my $self = shift;
    
    my $db_file = $self->home_dir . '/database/anycomic.db'; 

    return unless -f $db_file;

    state $schema;

    $schema //= AnyComic::Schema->connect("dbi:SQLite:$db_file", '', '', {sqlite_unicode => 1});

    return $schema;
}

sub _add_sites {
    my ($self, $sites) = @_;

    $sites = [$sites] if ref $sites eq 'HASH';
    
    croak qq{The add_sites parameter must be hash or array}
        unless ref $sites eq 'ARRAY';
     
    for my $site (@$sites) {
        my $domain = $site->{domain} || '[empty domain]';
        my $standard_domain = _get_standard_domain($domain); 
        my $site_name = $site->{name} || '[empty name]';

        unless ($standard_domain) {
            $self->log->error(qq{无效的域名：$domain. 忽略站点:$site_name});
            next;
        }
        
        if (exists $self->{_domain_map}{$standard_domain}) {
            $self->log->warn(qq{域名已经存在：$domain，站点数据将会被重置});
        }

        my $site_obj = AnyComic::Site->new(
            name => $site->{name},
            domain => $site->{domain},
            config => $site,
            books => [],
            app => $self
        );

        weaken($site_obj->{app});

        if (exists $self->{_domain_map}{$standard_domain}) {
            $self->{sites}[ $self->{_domain_map}{$standard_domain} ] = $site_obj;
        } else {
            my $len = push @{$self->{sites}}, $site_obj;
            $self->{_domain_map}{$standard_domain} = $len - 1;
        }

        $site_obj->save();
    }
}

sub get_site {
    my ($self, $domain) = @_;

    $domain = _get_standard_domain($domain); 

    return unless exists $self->{_domain_map}{$domain};
    
    return $self->{sites}[$self->{_domain_map}{$domain}];
}

sub reload_config {
    my ($self, $path) = @_;

    $path //= $self->site_config_dir;
    
    return $self->load_config($path);
}

sub load_config {
    my ($self, $path) = @_;

    my @files = ();

    if (-d $path) {
        $path .= '/' unless $path ~~ qr{/$};        
        @files = glob("${path}*.yml");
    } elsif (-f $path) {
        push @files, $path;
    }

    unless (@files) {
        carp "No config file found in path:$path";
        return;
    }
    
    for my $file (@files) {
        my $config = LoadFile($file);
        $self->_add_sites($config);
    }

    return 1;
}

sub _get_standard_domain {
    my $_ = shift;

    $_ = Mojo::URL->new($_)->host if /^http/i;

    my ($domain) = /([^.]+\.\w+)$/;

    return unless $domain;
    
    return lc $domain;
}
1;
