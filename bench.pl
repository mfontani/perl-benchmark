#!/usr/bin/env perl
use 5.020_000;
use warnings;
use Benchmark qw<countit>;
use Config qw<%Config>;

{
    package testAccessorArray;
    sub new { bless [ 42 ], shift }
    sub get { $_[0][0] }
    sub set { $_[0][0] = $_[1] }
}

{
    package testAccessorHash;
    sub new { bless { foo => 42 }, shift }
    sub get { $_[0]->{foo} }
    sub set { $_[0]->{foo} = $_[1] }
}

my @tests = (
    [ 'shiftAssign*26', sub {
        my @alphabet = ('A'..'Z');
        for (my $i = 0; $i < 26; $i++) {
            my $letter = shift @alphabet;
        }
        # return "@alphabet";
    } ],
    [ 'equalsAssign*26', sub {
        my @alphabet = ('A'..'Z');
        for (my $i = 0; $i < 26; $i++) {
            my $letter = $alphabet[$i];
        }
        # return "@alphabet";
    } ],
    [ 'accessorArray_new_get*1', sub {
        my $obj = testAccessorArray->new;
        for (my $i = 0; $i < 1; $i++) {
            my $val = $obj->get;
        }
    } ],
    [ 'accessorArray_new_set*1', sub {
        my $obj = testAccessorArray->new;
        for (my $i = 0; $i < 1; $i++) {
            $obj->set($i);
        }
    } ],
    [ 'accessorArray_new_get*100', sub {
        my $obj = testAccessorArray->new;
        for (my $i = 0; $i < 100; $i++) {
            my $val = $obj->get;
        }
    } ],
    [ 'accessorArray_new_set*100', sub {
        my $obj = testAccessorArray->new;
        for (my $i = 0; $i < 100; $i++) {
            $obj->set($i);
        }
    } ],
    [ 'accessorHash_new_get*1', sub {
        my $obj = testAccessorHash->new;
        for (my $i = 0; $i < 1; $i++) {
            my $val = $obj->get;
        }
    } ],
    [ 'accessorHash_new_set*1', sub {
        my $obj = testAccessorHash->new;
        for (my $i = 0; $i < 1; $i++) {
            $obj->set($i);
        }
    } ],
    [ 'accessorHash_new_get*100', sub {
        my $obj = testAccessorHash->new;
        for (my $i = 0; $i < 100; $i++) {
            my $val = $obj->get;
        }
    } ],
    [ 'accessorHash_new_set*100', sub {
        my $obj = testAccessorHash->new;
        for (my $i = 0; $i < 100; $i++) {
            $obj->set($i);
        }
    } ],
);

eval {
    use Class::Accessor;
    {
        package testAccessorClassAccessor;
        use base qw<Class::Accessor>;
        __PACKAGE__->mk_accessors(qw<foo>);
    }
    push @tests, [ 'accessorClassAccessor_new_get*1', sub {
        my $obj = testAccessorClassAccessor->new({ foo => 42 });
        for (my $i = 0; $i < 1; $i++) {
            my $val = $obj->foo;
        }
    } ];
    push @tests, [ 'accessorClassAccessor_new_set*1', sub {
        my $obj = testAccessorClassAccessor->new({ foo => 42 });
        for (my $i = 0; $i < 1; $i++) {
            $obj->foo($i);
        }
    } ];
    push @tests, [ 'accessorClassAccessor_new_get*100', sub {
        my $obj = testAccessorClassAccessor->new({ foo => 42 });
        for (my $i = 0; $i < 100; $i++) {
            my $val = $obj->foo;
        }
    } ];
    push @tests, [ 'accessorClassAccessor_new_set*100', sub {
        my $obj = testAccessorClassAccessor->new({ foo => 42 });
        for (my $i = 0; $i < 100; $i++) {
            $obj->foo($i);
        }
    } ];
};
if (my $error = $@) {
    warn "Skipping Class::Accessor tests: $error";
}

eval {
    use Class::Accessor::Fast;
    {
        package testAccessorClassAccessorFast;
        use base qw<Class::Accessor::Fast>;
        __PACKAGE__->mk_accessors(qw<foo>);
    }
    push @tests, [ 'accessorClassAccessorFast_new_get*1', sub {
        my $obj = testAccessorClassAccessorFast->new({ foo => 42 });
        for (my $i = 0; $i < 1; $i++) {
            my $val = $obj->foo;
        }
    } ];
    push @tests, [ 'accessorClassAccessorFast_new_set*1', sub {
        my $obj = testAccessorClassAccessorFast->new({ foo => 42 });
        for (my $i = 0; $i < 1; $i++) {
            $obj->foo($i);
        }
    } ];
    push @tests, [ 'accessorClassAccessorFast_new_get*100', sub {
        my $obj = testAccessorClassAccessorFast->new({ foo => 42 });
        for (my $i = 0; $i < 100; $i++) {
            my $val = $obj->foo;
        }
    } ];
    push @tests, [ 'accessorClassAccessorFast_new_set*100', sub {
        my $obj = testAccessorClassAccessorFast->new({ foo => 42 });
        for (my $i = 0; $i < 100; $i++) {
            $obj->foo($i);
        }
    } ];
};
if (my $error = $@) {
    warn "Skipping Class::Accessor::Fast tests: $error";
}

eval {
    require Class::XSAccessor;
    {
        package testAccessorClassXSAccessor;
        use Class::XSAccessor {
            constructor => 'new',
            accessors   => { "foo" => 123 },
        };
    }
    push @tests, [ 'accessorClassXSAccessor_new_get*1', sub {
        my $obj = testAccessorClassXSAccessor->new(foo => 42);
        for (my $i = 0; $i < 1; $i++) {
            my $val = $obj->foo;
        }
    } ];
    push @tests, [ 'accessorClassXSAccessor_new_set*1', sub {
        my $obj = testAccessorClassXSAccessor->new(foo => 42);
        for (my $i = 0; $i < 1; $i++) {
            $obj->foo($i);
        }
    } ];
    push @tests, [ 'accessorClassXSAccessor_new_get*100', sub {
        my $obj = testAccessorClassXSAccessor->new(foo => 42);
        for (my $i = 0; $i < 100; $i++) {
            my $val = $obj->foo;
        }
    } ];
    push @tests, [ 'accessorClassXSAccessor_new_set*100', sub {
        my $obj = testAccessorClassXSAccessor->new(foo => 42);
        for (my $i = 0; $i < 100; $i++) {
            $obj->foo($i);
        }
    } ];
};
if (my $error = $@) {
    warn "Skipping Class::XSAccessor tests: $error";
}

eval {
    require Class::XSAccessor::Array;
    {
        package testAccessorClassXSAccessorArray;
        use Class::XSAccessor::Array {
            constructor => 'new',
            accessors   => { "foo" => 123 },
        };
    }
    push @tests, [ 'accessorClassXSAccessorArray_new_get*1', sub {
        my $obj = testAccessorClassXSAccessorArray->new(foo => 42);
        for (my $i = 0; $i < 1; $i++) {
            my $val = $obj->foo;
        }
    } ];
    push @tests, [ 'accessorClassXSAccessorArray_new_set*1', sub {
        my $obj = testAccessorClassXSAccessorArray->new(foo => 42);
        for (my $i = 0; $i < 1; $i++) {
            $obj->foo($i);
        }
    } ];
    push @tests, [ 'accessorClassXSAccessorArray_new_get*100', sub {
        my $obj = testAccessorClassXSAccessorArray->new(foo => 42);
        for (my $i = 0; $i < 100; $i++) {
            my $val = $obj->foo;
        }
    } ];
    push @tests, [ 'accessorClassXSAccessorArray_new_set*100', sub {
        my $obj = testAccessorClassXSAccessorArray->new(foo => 42);
        for (my $i = 0; $i < 100; $i++) {
            $obj->foo($i);
        }
    } ];
};
if (my $error = $@) {
    warn "Skipping Class::XSAccessor::Array tests: $error";
}

eval {
    require Moo;
    {
        package testAccessorMoo;
        use Moo;
        has foo => (is => 'rw', default => 123);
    }
    push @tests, [ 'accessorMoo_new_get*1', sub {
        my $obj = testAccessorMoo->new({ foo => 42 });
        for (my $i = 0; $i < 1; $i++) {
            my $val = $obj->foo;
        }
    } ];
    push @tests, [ 'accessorMoo_new_set*1', sub {
        my $obj = testAccessorMoo->new({ foo => 42 });
        for (my $i = 0; $i < 1; $i++) {
            $obj->foo($i);
        }
    } ];
    push @tests, [ 'accessorMoo_new_get*100', sub {
        my $obj = testAccessorMoo->new({ foo => 42 });
        for (my $i = 0; $i < 100; $i++) {
            my $val = $obj->foo;
        }
    } ];
    push @tests, [ 'accessorMoo_new_set*100', sub {
        my $obj = testAccessorMoo->new({ foo => 42 });
        for (my $i = 0; $i < 100; $i++) {
            $obj->foo($i);
        }
    } ];
};
if (my $error = $@) {
    warn "Skipping Moo tests: $error";
}

eval {
    require Moose;
    {
        package testAccessorMoose;
        use Moose;
        has foo => (is => 'rw', default => 123);
    }
    push @tests, [ 'accessorMoose_new_get*1', sub {
        my $obj = testAccessorMoose->new({ foo => 42 });
        for (my $i = 0; $i < 1; $i++) {
            my $val = $obj->foo;
        }
    } ];
    push @tests, [ 'accessorMoose_new_set*1', sub {
        my $obj = testAccessorMoose->new({ foo => 42 });
        for (my $i = 0; $i < 1; $i++) {
            $obj->foo($i);
        }
    } ];
    push @tests, [ 'accessorMoose_new_get*100', sub {
        my $obj = testAccessorMoose->new({ foo => 42 });
        for (my $i = 0; $i < 100; $i++) {
            my $val = $obj->foo;
        }
    } ];
    push @tests, [ 'accessorMoose_new_set*100', sub {
        my $obj = testAccessorMoose->new({ foo => 42 });
        for (my $i = 0; $i < 100; $i++) {
            $obj->foo($i);
        }
    } ];
};
if (my $error = $@) {
    warn "Skipping Moose tests: $error";
}

eval {
    require Object::Tiny::RW;
    {
        package testAccessorObjectTinyRW;
        use Object::Tiny::RW qw<foo>;
    }
    push @tests, [ 'accessorObjectTinyRW_new_get*1', sub {
        my $obj = testAccessorObjectTinyRW->new({ foo => 42 });
        for (my $i = 0; $i < 1; $i++) {
            my $val = $obj->foo;
        }
    } ];
    push @tests, [ 'accessorObjectTinyRW_new_set*1', sub {
        my $obj = testAccessorObjectTinyRW->new({ foo => 42 });
        for (my $i = 0; $i < 1; $i++) {
            $obj->foo($i);
        }
    } ];
    push @tests, [ 'accessorObjectTinyRW_new_get*100', sub {
        my $obj = testAccessorObjectTinyRW->new({ foo => 42 });
        for (my $i = 0; $i < 100; $i++) {
            my $val = $obj->foo;
        }
    } ];
    push @tests, [ 'accessorObjectTinyRW_new_set*100', sub {
        my $obj = testAccessorObjectTinyRW->new({ foo => 42 });
        for (my $i = 0; $i < 100; $i++) {
            $obj->foo($i);
        }
    } ];
};

my $done = 0;
for my $test (@tests) {
    my ($name, $code) = @$test;
    my $res = countit(-10, $code);
    say join "\t", @ARGV, $Config{version}, $name, map { sprintf '%.2f', $_ } $res->iters / $res->cpu_p, $res->real, $res->iters, $res->cpu_p;
    $done++;
    # exit if $done >= 2; # exit after 2 tests, for testing.
}
