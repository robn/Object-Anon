[![Build Status](https://secure.travis-ci.org/robn/Object-Anon.png)](http://travis-ci.org/robn/Object-Anon)

# NAME

Object::Anon - Create objects on the fly

# SYNOPSIS

    use Object::Anon;

    # create an object from a hash
    my $o = anon { foo => "bar" };
    say $o->foo; # prints "bar";
    say $o->baz; # dies, no such method

    # deep hashes will turn into deep objects
    my $o = anon { foo => { bar => "baz" } };
    say $o->foo->bar; # prints "baz"

    # so do arrays
    my $o = anon { foo => [ { n => 1 }, { n => 2 }, { n => 3 } ] };
    say $o->foo->[2]->n; # prints "3"

    # overloading
    my $o = anon { foo => "bar", '""' => "baz" };
    say $o->foo; # prints "bar"
    say $o;      # prints "baz"

# WARNING

This module is highly experimental. I think the idea is sound, but there's a
bunch of important design points that I haven't yet finalised. See [TODO](https://metacpan.org/pod/TODO) for
details, and take care when using this in your own code.

# DESCRIPTION

This modules exports a single function `anon` that takes a hash as its
argument and returns an object with methods corresponding to the hash keys.

Why would you want this? Well, its not at all uncommon to want to return a hash
from some function. The problem is the usual one with hashes - its too easy to
mistype a key and silently fail without knowing exactly where you went wrong.

Returning an object fixes this problem since an attempt to call a missing
method results in a fatal error. Unfortunately there's lots of boilerplate
required to create a class for every kind of return type. And that's why this
module exists - it make it trivially easy to convert a hash into an object,
with nothing else to worry about.

# INTERFACE

This module exports a single function `anon`. When called with a hashref as
its argument, it returns an object with methods named for the hash keys that
return the corresponding value.

It does this by installing simple read accessors into a class with a randomised
name, then blessing an empty hash into that class and returning it. The methods
are named for the keys, and return a copy of the value found in the hash key.

The call:

    $o = anon { foo => "bar", baz => "quux" };

produces similar results to the following code:

    package random::class::1;
    sub foo { "bar" }
    sub baz { "quux" }
    $o = bless {}, "random::class::1";

## Value handling

There is special handling for certain value types to make them more useful.

- hashes

    Hashes will be converted to objects in turn. So this:

        $o = anon { foo => { bar => "baz" } };

    becomes similar in function to:

        package random::class::1;
        sub bar { "baz" }
        package random::class::2;
        sub foo { bless {}, "random::class::1" }
        $o = bless {}, "random::class::2";

    except that all the bless stuff happens up-front, not at call time.

- arrays

    Arrays of hashes are similarly handled, returning instead an array of objects.

- coderefs

    Coderefs are installed as-is, that is:

        $o = anon { foo => sub { "bar" } };

    becomes:

        package random::class::1;
        sub foo { "bar" }
        $o = bless {}, "random::class::1";

## Overloading

If a hash key is one of the overload operators (see [overload](https://metacpan.org/pod/overload)) then an
overload function will be installed instead of the named key:

    $o = anon { foo => "bar", '""' => "baz" };

becomes something like:

    package random::class::1;
    sub foo { "bar" }
    use overload '""' => sub { "baz" };
    $o = bless {}, "random::class::1";

Be aware that simple strings won't suffice for many kinds of overload (like
comparison operators), so much of the time you'll want to pass a coderef.
`Object::Anon` won't do anything special with the code it generates for
overloads, so things like this can give odd results:

    $o = anon { "+" => "foo" }; # addition overload
    say $o + 3; # prints "foo";

# TODO

Much of this is design that I haven't quite figured out yet (mostly because I
haven't had a strong need for it yet). If you have thoughts about any of this,
please let me know!

- Class caching. It'd be nice for the same return in a busy function to be able
to reuse the class that was generated last time. The only difficulty is
determining when to do this. [Net::Twitter](https://metacpan.org/pod/Net::Twitter) does this with data returned from
the Twitter API by taking a SHA1 of the returned keys and uses that as a cache
key for a Moose metaclass. That's a nice approach when you know the incoming
hash is always JSON, but doesn't work as well when you can't predict the value
type (especially if the value is a coderef). Including the value type in the
cache key and not caching at all when coderefs are seen might work, but may be
too limiting. Another approach might involve looking at the caller, on the
basis that the same point in the code is probably returning the same structure
each time.
- Overload clashes. Some overloaded operators are common words. If a hash had a
key of that name it would generate an overload, not a method of that name,
which isn't want you want. The only ways I can think of to deal with this is to
either limit the set of possible overload operators to ones unlikely to clash
(the symbol ones), or to make overload specified by an option or similar.
Neither of these options particularly appeal to me though.
- Return hash. Should it be filled with the original data so you can access the
data as a hash as well as via the methods? I'm inclined to think not,
particularly since that makes it modifiable which then brings up a question of
whether or not those changes should be reflected in the the data return from
the methods. But if you wanted to then pass the hash to something else, it
won't do the right thing either. Maybe a hash deref overload?

# SEE ALSO

- [Object::Result](https://metacpan.org/pod/Object::Result) - another way of addressing the same problem. This was
actually the direct inspiration for `Object::Anon`. I liked the idea, but
hated that it defined its own syntax and required [PPI](https://metacpan.org/pod/PPI).

# SUPPORT

## Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at [https://github.com/robn/Object-Anon/issues](https://github.com/robn/Object-Anon/issues).
You will be notified automatically of any progress on your issue.

## Source Code

This is open source software. The code repository is available for
public review and contribution under the terms of the license.

[https://github.com/robn/Object-Anon](https://github.com/robn/Object-Anon)

    git clone https://github.com/robn/Object-Anon.git

# AUTHORS

- Robert Norris <rob@eatenbyagrue.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Robert Norris.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
