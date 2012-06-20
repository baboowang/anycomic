package AnyComic::Schema::ResultSet::ReadLog;
use base 'DBIx::Class::ResultSet';

sub update_log {
    my ($self, $book_id, $period_id) = @_;

    my $data = {
        book_id => $book_id,
        last_period_id => $period_id,
        last_time => \'CURRENT_TIMESTAMP',
    };

    $self->update_or_create($data, { key => 'primary' });
}
1;


