package AnyComic::Schema::Result::Image;
use base 'DBIx::Class::Core';

__PACKAGE__->table('image');
__PACKAGE__->add_columns(qw/id url local_path/);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->has_many(page => 'AnyComic::Schema::Result::Page', 'image_id');
__PACKAGE__->has_many(cover => 'AnyComic::Schema::Result::Cover', 'image_id');
1;
