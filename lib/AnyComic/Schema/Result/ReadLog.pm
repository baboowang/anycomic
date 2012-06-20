package AnyComic::Schema::Result::ReadLog;
use base 'DBIx::Class::Core';

__PACKAGE__->table('read_log');
__PACKAGE__->add_columns(qw/book_id last_period_id last_time/);
__PACKAGE__->set_primary_key('book_id');
__PACKAGE__->has_one(book => 'AnyComic::Schema::Result::Book', 'id');
__PACKAGE__->has_one(period => 'AnyComic::Schema::Result::Period', { 'foreign.id' => 'self.last_period_id' });
1;
