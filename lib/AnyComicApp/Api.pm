package AnyComicApp::Api;
use Mojo::Base 'AnyComicApp::Controller';
use AnyComicApp::Utils;
use utf8;

sub ping {
    shift->ajax_result(1);
}
1;


