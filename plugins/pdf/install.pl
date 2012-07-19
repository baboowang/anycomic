#!/usr/bin/env perl 
#===============================================================================
#
#         FILE: setup.pl
#
#        USAGE: ./setup.pl  
#
#  DESCRIPTION: 
#
#      OPTIONS: ---
# REQUIREMENTS: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Baboo (8boo.net), baboo.wg@gmail.com
# ORGANIZATION: 
#      VERSION: 1.0
#      CREATED: 2012/07/18 16时44分09秒
#     REVISION: ---
#===============================================================================

use lib '../../lib';
use AnyComic::Version;

my @modules = qw/PDF::API2/;

install_modules(@modules);
