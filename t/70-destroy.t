#!/usr/bin/env perl

use warnings;
use strict;
use Test::More;

use Object::Anon;
use Scalar::Util qw(blessed);

my $o = anon { foo => "bar" };
my $package = blessed $o;

my $symtab = do { no strict 'refs'; *{$package.'::'}{HASH} };
is keys %$symtab, 1, "symbol table has one key";
is_deeply [sort keys %$symtab], [qw(foo)], "symbol table has expected keys";

undef $o;

is keys %$symtab, 0, "symbol table has no keys";
my ($root, $id) = $package =~ m/^(.+)::(\d+)$/;
ok !exists do { no strict 'refs'; *{$root.'::'}{HASH}}->{$id.'::'}, "package no longer exists";

done_testing;

