package Object::Anon;

# ABSTRACT: Create objects on the fly

use strict;
use warnings;

use Moose ();
use Moose::Meta::Class ();
use Moose::Util::TypeConstraints qw(class_type coerce from via);

use Exporter qw(import);
our @EXPORT = qw(anon);

sub anon (%) {
    my ($hash) = @_;
    return _inflate_class_for($hash)->new_object($hash);
}

use overload ();
my %overload_ops = map { $_ => 1 } map { split /\s+/, $_ } values %overload::ops;

sub _inflate_class_for {
    my ($hash) = @_;

    my $meta = Moose::Meta::Class->create_anon_class;

    class_type($meta->name);
    coerce($meta->name => from 'HashRef' => via { $meta->new_object($_) });

    for my $key (keys %$hash) {
        my $value = $hash->{$key};

        if ($overload_ops{$key}) {
            $meta->add_overloaded_operator($key => ref $value eq 'CODE' ? $value : sub { $value });
        }
        else {
            my @args = {
                HASH  => sub { return (isa => _inflate_class_for($value)->name, coerce => 1) },
                ARRAY => sub { return (isa => 'ArrayRef') },
                CODE  => sub { return (isa => 'CodeRef', traits => ['Code'], reader => "___$key", handles => { $key => 'execute' }) },
                ""    => sub { return (isa => 'Str') },
            }->{ref $value}->();

            $meta->add_attribute($key, is => 'ro', @args);
        }
    }

    return $meta;
}

1;
