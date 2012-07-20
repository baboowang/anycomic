#!/usr/bin/perl
require 5.12.0;

use lib 'lib';
use AnyComic::Version;
use AnyComic::Locale;
use utf8;

my $locale_encoding = $AnyComic::Locale::ENCODING_CONSOLE_OUT;
binmode(STDOUT, ":encoding($locale_encoding)");

sub setup {
    use File::Copy;
    
    if ($^O ~~ /Win32/i && system('perl -v > NUL 2>&1') == 0) {
        print "请重启电脑后，重新运行该程序，按任意键退出\n";
        <>;
        exit;
    }

    print "开始安装...\n";

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
    print '-' x 80, "\n"; 
    print ' ' x 8, "服务启动成功后，请使用浏览器访问 http://127.0.0.1:3000 \n";
    print '-' x 80, "\n"; 
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
        print "请重启电脑后，重新运行该程序，按任意键退出\n";
        <>;
        exit;
    }

    print "\n\n启动服务...\n";
}

check_module_update;

start;
