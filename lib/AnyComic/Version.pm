use strict;
use warnings;
use utf8;

package AnyComic::Version;

use Exporter 'import';

our $VERSION = "0.1.5";

our @EXPORT = qw/install_modules check_module_update check_database_update update_module_version/;

my $default_version = '0.1.1';

sub install_modules {
    my @modules = @_;

    if ($^O ~~ /Win32/i && system('ppm help > NUL 2>&1') == 0) {
        system("ppm install $_") for @modules; 
    } else {
        system("cpan $_") for @modules;
    }
}

sub get_module_version {
    my $version_file = shift; 
    return $default_version unless -f $version_file;

    open my $fh, '<', $version_file;
    (my $version = <$fh>) =~ s/^\s+|\s+$//g;
    close $fh;

    return $version;
}

sub update_module_version {
    my $version_file = shift;
    open my $fh, '>', $version_file or die "$!";
    print $fh $VERSION;
    close $fh;
}

sub get_update_files {
    my ($version_file, $file_glob) = @_;
    my $app_version = $VERSION;
    my $module_version = get_module_version($version_file);
    
    my @files = ();

    return @files if $app_version eq $module_version;

    my @module_files = glob("updates/$file_glob");

    for my $module_file (sort @module_files) {
        my ($version) = $module_file =~ m/([\d_]+)\.(\w+)$/;
        $version =~ tr/_/./;
        next unless $version gt $module_version;
        
        push @files, $module_file;
    } 

    return @files;
}

sub check_module_update {
    my $version_file = 'updates/.version';
    my @module_files = get_update_files($version_file, '*.m');

    return unless @module_files;

    for my $module_file (@module_files) {

        open my $fh, '<', $module_file;
        my $content = do { local $/ = <$fh> };
        close $fh;
            
        my @modules = map { s/^\s+|\s+$//g; $_ } split /\s+/, $content;
        install_modules(@modules);
    }

    update_module_version($version_file);
}

sub check_database_update {
    my $dbh = shift;
    my $version_file = 'database/.version';

    my @sql_files = get_update_files($version_file, '*.sql');
    
    return unless @sql_files;
    for my $sql_file (sort @sql_files) {
        open my $fh, '<:utf8', $sql_file;
        my $content = do { local $/ = <$fh> };

        for my $sql (split(/;/, $content)) {
            $sql =~ s/^\s+|\s+$//g;
            next unless $sql;

            $dbh->do($sql);
        }

        close $fh;
    }
    
    update_module_version($version_file);
}

1;
