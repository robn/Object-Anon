package Object::Anon;

# ABSTRACT: Create objects on the fly

use strict;
use warnings;

use Sub::Install ();

use Exporter qw(import);
our @EXPORT = qw(anon);

sub anon (%) {
    my ($hash) = @_;
    return _objectify($hash);
}

use overload ();
my %overload_ops = map { $_ => 1 } map { split /\s+/, $_ } values %overload::ops;

my $anon_class_id = 0;

sub _objectify {
    my ($hash) = @_;

    my $class = "Object::Anon::__ANON__::".$anon_class_id++;

    for my $key (keys %$hash) {
        if ($overload_ops{$key}) {
            $class->overload::OVERLOAD($key => _value_sub($hash->{$key}));
        }
        else {
            Sub::Install::install_sub({
                code => _value_sub($hash->{$key}),
                into => $class,
                as   => $key,
            });
        }
    }

    return bless do { \my %o }, $class;
}

sub _value_sub {
    my ($value) = @_;

    do {
        {
            HASH  => sub { my $o = _objectify($value); sub { $o } },
            ARRAY => sub { my @o = map { _value_sub($_)->() } @$value; sub { \@o } },
            CODE  => sub { $value },
        }->{ref $value} // sub { sub { $value } }
    }->();
}

1;
