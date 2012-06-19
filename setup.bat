@echo Install perl modules
@call ppm install Mojolicious
@call ppm install MojoX::Renderer::Xslate
@call ppm install Modern::Perl
@call ppm install DBIx::Class
@call ppm install Encode::Locale
@echo Install database
if not exist database\anycomic.db ren database\anycomic.db.bak anycomic.db
pause
