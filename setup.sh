#/bin/bash
echo Install perl modules
cpan Mojolicious MojoX::Renderer::Xslate Modern::Perl DBIx::Class
echo Install database
if [ ! -e "database/anycomic.db" ]
then
    mv database/anycomic.db.bak database/anycomic.db
fi
