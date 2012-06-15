package AnyComicApp;
use Mojo::Base 'Mojolicious';
use AnyComicApp::Controller;
use AnyComicApp::Utils;
use AnyComic;
use Modern::Perl;

# This method will run once at server start
sub startup {
    my $self = shift;

    $self->secret("Most of the time, life is boring.");

    $self->controller_class('AnyComicApp::Controller');

    push @{$self->plugins->namespaces}, 'AnyComicApp::Plugin';

    # Documentation browser under "/perldoc"
    $self->plugin('PODRenderer');

    #Template-Xslate
    $self->plugin(xslate_renderer => {
        template_options => {
            function => {
                cutstr => sub {
                    my ($len) = @_;
                    return sub {
                        return cutstr(shift, $len);
                    };
                },
            },
        },
    });

    
    my $anycomic = AnyComic->new(home_dir => $self->home->to_string);

    $self->helper(anycomic => sub {
        return $anycomic;
    });

    #Add comic image directory to the static path
    push @{$self->static->paths}, $self->home->rel_dir('download');

    $self->plugin('AppHelpers');

    # Default stash
    #$self->defaults();

    $self->types->type(json => 'application/json; charset=utf-8;'); 

    # Router
    my $r = $self->routes;

    # Normal route to controller
#    $r->route('/:template', template => ['about', 'download', 'query']);
    $r->route('/:controller/:action')->to(controller => 'index', action => 'index');
}
1;
