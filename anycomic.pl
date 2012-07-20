#!/usr/bin/perl
require 5.12.0;

use lib 'lib';
use AnyComic::Version;

binmode(STDOUT, ':locale');

sub setup {
    use File::Copy;

    print "Install...\n";

    # 1. Install dependencies
    my @modules = qw/Mojolicious MojoX::Renderer::Xslate Modern::Perl DBIx::Class Encode::Locale/;
    install_modules(@modules);

    # 2. Install database
    move('database/anycomic.db.bak', 'database/anycomic.db') unless -e 'database/anycomic.db'; 

    # 3. Create directories
    mkdir('log') unless -d 'log';
    mkdir('updates') unless -d 'updates';
    

    update_module_version('updates/.version');
    update_module_version('database/.version');
}

sub start {
    # 监听地址
    $listen = "http://*:3000";

    system("morbo script/anycomic -l $listen");
}

eval {
    require Mojolicious;
};

my $module_installed = $@ ? 0 : 1;

if ( ! -f 'database/anycomic.db' or ($ARGV[0] && $ARGV[0] eq 'setup') or ! $module_installed) {
    setup;
    
    eval {
        require Mojolicious;
    };

    if ($@) {
        print "Please restart your computer, then run this file again.\n";
        <>;
        exit;
    }

    print "\n\nStart...\n";
}

check_module_update;

start;
