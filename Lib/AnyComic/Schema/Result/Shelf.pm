package AnyComic::Schema::Result::Shelf;
use base 'DBIx::Class::Core';

__PACKAGE__->table('shelf');
__PACKAGE__->add_columns(qw/book_id add_time last_period_update_time weight/);
__PACKAGE__->set_primary_key('book_id');
__PACKAGE__->has_one(book => 'AnyComic::Schema::Result::Book', 'id');
1;
