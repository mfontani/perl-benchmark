#!/usr/bin/env perl
use 5.020_000;
use warnings;

my @perls = (
    [ '5.38.1', '6a82c7930563086e78cb84d9c265e6b212ee65d509d19eedcd23ab8c1ba3f046' ],
    [ '5.38.0', 'eca551caec3bc549a4e590c0015003790bdd1a604ffe19cc78ee631d51f7072e' ],
    [ '5.36.1', 'bd91217ea8a8c8b81f21ebbb6cefdf0d13ae532013f944cdece2cd51aef4b6a7' ],
    [ '5.34.1', '6d52cf833ff1af27bb5e986870a2c30cec73c044b41e3458cd991f94374039f7' ],
);

my @variations = (
    [ 'threaded-taint',    '-Dusethreads' ],
    [ 'threaded-notaint',  '-Dusethreads -Accflags=-DSILENT_NO_TAINT_SUPPORT' ],
    [ 'nothreads-taint',   '' ],
    [ 'nothreads-notaint', '-Accflags=-DSILENT_NO_TAINT_SUPPORT'],
);

my $dockerfile_template = <<'END';
# See https://github.com/Perl/docker-perl/
FROM debian:bullseye-slim
WORKDIR /usr/src/perl
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       bzip2 \
       ca-certificates \
       curl \
       dpkg-dev \
       gcc \
       libc6-dev \
       make \
       netbase \
       patch \
       zlib1g-dev \
       xz-utils \
       libssl-dev
RUN \
    curl -fL https://www.cpan.org/src/5.0/perl-%s.tar.xz -o perl-%s.tar.xz \
    && echo '%s *perl-%s.tar.xz' | sha256sum --strict --check - \
    && tar --strip-components=1 -xaf perl-%s.tar.xz -C /usr/src/perl \
    && rm perl-%s.tar.xz
RUN ./Configure -Duse64bitall %s -Duseshrplib -Doptimize='-O2 -march=x86-64 -pipe' -Accflags=-fPIC -Dvendorprefix=/usr/local -des
RUN make -j$(nproc)
RUN make install
RUN curl -L https://cpanmin.us/ -o /usr/local/bin/cpanm && chmod +x /usr/local/bin/cpanm && /usr/local/bin/cpanm
RUN cpanm --notest \
    Class::Accessor Class::Accessor::Fast \
    Class::XSAccessor Class::XSAccessor::Array \
    Moo Moose \
    Object::Tiny::RW \
    Benchmark
ADD bench.pl /bench.pl
ENTRYPOINT ["/usr/local/bin/perl", "/bench.pl", "%s"]
END

my $build_script = <<'END';
#!/bin/bash
set -euo pipefail
makefile_all=""
rm -f Makefile Makefile.tmp
# Build images:
END
my $eoscript = '';
my $total = scalar(@perls) * scalar(@variations);
my $i = 1;
for my $variation_spec (@variations) {
    my ($variation, $flags) = @$variation_spec;
    for my $perl_spec (@perls) {
        my ($perl_version, $sha256) = @$perl_spec;
        my $dir = "perl-$perl_version-$variation";
        mkdir $dir
            if !-d $dir;
        my $contents = sprintf $dockerfile_template,
            $perl_version, $perl_version, $sha256, $perl_version, $perl_version, $perl_version,
            $flags, "perl-$perl_version-$variation";
        open my $fh, '>', "$dir/Dockerfile"
            or die "Can't open $dir/Dockerfile: $!";
        print $fh $contents;
        close $fh
            or die "Can't close $dir/Dockerfile: $!";
        $build_script .= "docker build -t perl-tests:$perl_version-$variation -f $dir/Dockerfile .\n";
        $eoscript .= <<"END";
sha=\$(docker inspect "perl-tests:$perl_version-$variation" --format='{{.Id}}')
sha=\${sha#"sha256:"}
makefile_all="\$makefile_all $dir/\$sha.tsv"
echo "$dir/\$sha.tsv:" >> Makefile.tmp
echo "\t\@echo Benchmarking \\\$@ ..." >> Makefile.tmp
echo "\tdocker run -it --rm perl-tests:$perl_version-$variation | tee \\\$@" >> Makefile.tmp
END
        $i++;
    }
}
$eoscript .= <<"END";
echo "clean:" >> Makefile.tmp
echo "\trm -f bench.tsv" >> Makefile.tmp
echo "\trm -f perl*/*.tsv" >> Makefile.tmp
echo "bench_head.tsv:" >> Makefile.tmp
echo "\techo 'variation\tversion\tname\titers/cpu_p\treal\titers\tcpu_p' > \\\$@" >> Makefile.tmp
echo "bench.tsv: bench_head.tsv \$makefile_all" >> Makefile.tmp
echo "\tcat \$^ > \\\$@" >> Makefile.tmp
echo "all: clean bench_head.tsv \$makefile_all bench.tsv" > Makefile
cat Makefile.tmp >> Makefile
rm -f Makefile.tmp
END

{
    open my $fh, '>', 'build.sh'
        or die "Can't open build.sh: $!";
    print $fh $build_script;
    print $fh $eoscript;
    close $fh
        or die "Can't close build.sh: $!";
    chmod 0755, 'build.sh';
}
