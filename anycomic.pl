#!/usr/bin/perl
require 5.12.0;

sub setup {
    use File::Copy;

    print "Install...\n";

    # 1. Install dependencies
    my @modules = qw/Mojolicious MojoX::Renderer::Xslate Modern::Perl DBIx::Class Encode::Locale/;

    if ($^O ~~ /Win32/i && system('ppm help > NUL 2>&1') == 0) {
        system("ppm install $_") for @modules; 
    } else {
        system("cpan $_") for @modules;
    }

    # 2. Install database
    move('database/anycomic.db.bak', 'database/anycomic.db') unless -e 'database/anycomic.db'; 

    # 3. Create log directory
    mkdir('log') unless -d 'log';
}

sub start {
    # 监听地址
    $listen = "http://*:3000";

    system("morbo script/anycomic -l $listen");
}

if ( ! -f 'database/anycomic.db' or ($ARGV[0] && $ARGV[0] eq 'setup') ) {
    setup;
    
    print "\n\nStart...\n";
}

start;
