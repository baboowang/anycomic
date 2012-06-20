package AnyComic::Schema::Result::Period;
use base 'DBIx::Class::Core';

__PACKAGE__->table('period');
__PACKAGE__->add_columns(qw/id name url book_id page_count period_no/);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->belongs_to(book => 'AnyComic::Schema::Result::Book', 'book_id');
__PACKAGE__->has_many(pages => 'AnyComic::Schema::Result::Page', 'period_id');
1;
