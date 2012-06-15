package AnyComic::Book::Cover;
use Mojo::Base 'AnyComic::ImageBase';
use utf8;

use overload
    '""' => sub { shift->url },
    fallback => 1;

has [qw/book/];
has site => sub { shift->book->site };
has app  => sub { shift->book->app };
has autoload => 1;

sub download {
    my $self = shift;

    return 1 if $self->downloaded;

    my $ret = $self->_download(
        $self->book->url, 
        $self->site->name . ' ' . $self->book->name . ' 封面图片', 
        $self->book->data_dir
    );

    $self->save() if $ret;

    return $ret;
}

sub _on_save {
    my ($self, $data) = @_;

    return unless $self->local_path;

    my $image = {
        url => $self->url,
        local_path => $self->local_path,
    };
    $image->{id} = $self->_get_url_key($image->{url});
    
    return unless 
        $self->get_schema->resultset('Image')
             ->update_or_create($image, { key => 'primary' });

    $data->{image_id} = $image->{id};
    $data->{book_id} = $self->book->id;

    return 1;
}

sub _on_load {
    my ($self, $row) = @_;

    if (my $image = $row->image) {
        if (-f $image->local_file) {
            $self->_set_downloaded($image->local_file);
        }
    }

    return 1;
}
1;
