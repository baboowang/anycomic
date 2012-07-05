package AnyComicApp;
use Mojo::Base 'Mojolicious';
use AnyComicApp::Controller;
use AnyComicApp::Utils;
use Text::Xslate::Util qw/mark_raw/;
use AnyComic;
use AnyComic::Version;
use Modern::Perl;
use utf8;

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
                jsstr => sub {
                    return mark_raw(jsstr(shift));
                },
            },
        },
    });
    
    my $anycomic = AnyComic->new(home_dir => $self->home->to_string);
    if ($self->mode eq 'production') {
        $anycomic->log->level('error');
        $anycomic->log->path($self->home->rel_file('log/production.log'));
    }

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

    check_database_update($anycomic->get_schema->storage->dbh);
}
1;
