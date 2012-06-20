package AnyComic::Schema::Result::Book;
use base 'DBIx::Class::Core';

__PACKAGE__->table('book');
__PACKAGE__->add_columns(qw/id name url site_id author status cates area last_update_period update_time intro/);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->belongs_to(site => 'AnyComic::Schema::Result::Site', 'site_id');
__PACKAGE__->has_many(periods => 'AnyComic::Schema::Result::Period', 'book_id');
__PACKAGE__->has_one(cover => 'AnyComic::Schema::Result::Cover', 'book_id');
1;
