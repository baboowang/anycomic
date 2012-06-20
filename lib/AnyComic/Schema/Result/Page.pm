package AnyComic::Schema::Result::Page;
use base 'DBIx::Class::Core';

__PACKAGE__->table('page');
__PACKAGE__->add_columns(qw/id period_id url image_id page_no/);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->belongs_to(period => 'AnyComic::Schema::Result::Period', 'period_id');
__PACKAGE__->belongs_to(image => 'AnyComic::Schema::Result::Image', 'image_id');
1;
