package AnyComic::Schema::Result::Cover;
use base 'DBIx::Class::Core';

__PACKAGE__->table('cover');
__PACKAGE__->add_columns(qw/id url book_id image_id/);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->belongs_to(book => 'AnyComic::Schema::Result::Book', 'book_id');
__PACKAGE__->belongs_to(image => 'AnyComic::Schema::Result::Image', 'image_id');
1;
