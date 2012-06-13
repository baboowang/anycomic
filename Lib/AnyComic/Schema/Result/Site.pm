package AnyComic::Schema::Result::Site;
use base 'DBIx::Class::Core';

__PACKAGE__->table('site');
__PACKAGE__->add_columns(qw/id domain name config/);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->has_many(books => 'AnyComic::Schema::Result::Book', 'site_id');
1;
