#!/usr/bin/env perl
use 5.020_000;
use warnings;
use Path::Tiny qw<path>;
use Chart::Plotly qw<>;
use Chart::Plotly::Trace::Bar qw<>;
use Chart::Plotly::Plot qw<>;

# We have a number of tests, done on a number of different versions of perl and
# with varying {threaded,nothreads} and {taint,notaint}.
# Report, with charts, the results of these tests.
# Multiple bench*.tsv might be present, so we need to merge them. In those
# cases, the values are the average and we provide an "error bar" for each
# result, to show the variation in results.

my %by_test_name;
{
    for my $file (glob('report/bench*.tsv')) {
        my @lines = path($file)->lines_utf8({ chomp => 1 });
        shift @lines; # header
        for my $line (@lines) {
            my ($perl_spec, $_perl_version, $test_name, $iters_per_cpu_p, $real, $iters, $cpu_p) = split /\t/, $line;
            my ($perl, $perl_version, $threaded, $tainted) = split /-/, $perl_spec; # perl-5.38.0-threaded-taint
            $by_test_name{$test_name} //= {};
            $by_test_name{$test_name}{$threaded}{$tainted}{$perl_version} //= {
                spec => "$perl_version-$threaded-$tainted",
                iters_per_cpu_p => [],
            };
            push @{ $by_test_name{$test_name}{$threaded}{$tainted}{$perl_version}{iters_per_cpu_p} }, $iters_per_cpu_p;
        }
    }
    # Munge & provide:
    # - average
    # - standard deviation
    for my $test (sort keys %by_test_name) {
        for my $threaded (sort keys %{ $by_test_name{$test} }) {
            for my $tainted (sort keys %{ $by_test_name{$test}{$threaded} }) {
                for my $perl_version (sort keys %{ $by_test_name{$test}{$threaded}{$tainted} }) {
                    my $iters_per_cpu_p = $by_test_name{$test}{$threaded}{$tainted}{$perl_version}{iters_per_cpu_p};
                    my $avg = 0;
                    $avg += $_ for @$iters_per_cpu_p;
                    $avg /= @$iters_per_cpu_p;
                    my $stddev = 0;
                    $stddev += ($_ - $avg)**2 for @$iters_per_cpu_p;
                    $stddev /= @$iters_per_cpu_p;
                    $stddev = sqrt($stddev);
                    $by_test_name{$test}{$threaded}{$tainted}{$perl_version}{avg} = $avg;
                    $by_test_name{$test}{$threaded}{$tainted}{$perl_version}{stddev} = $stddev;
                }
            }
        }
    }
}

if (!-d 'report') {
    mkdir 'report' or die "mkdir report: $!";
}

my $index = <<'END';
<!DOCTYPE html>
<html>
<head>
<title>Perl benchmark results - higher is better</title>
</head>
<body>
<h1>Perl benchmark results - higher is better</h1>
END

for my $test_name (sort keys %by_test_name) {
    my $test = $by_test_name{$test_name};
    $index .= "<h2><code>$test_name</code> per second</h2>\n";
    my @perl_versions;
    {
        my @x;
        for my $threaded (sort keys %$test) {
            for my $tainted (sort keys %{$test->{$threaded}}) {
                push @x, "$threaded-$tainted";
            }
        }
        my %series;
        my %series_error;
        for my $threaded (sort keys %$test) {
            for my $tainted (sort keys %{$test->{$threaded}}) {
                for my $perl_version (sort keys %{$test->{$threaded}{$tainted}}) {
                    push @{ $series{ $perl_version } }, $test->{$threaded}{$tainted}{$perl_version}{avg};
                    push @{ $series_error{ $perl_version } }, $test->{$threaded}{$tainted}{$perl_version}{stddev} * 2;
                }
            }
        }
        @perl_versions = sort keys %series;
        my @traces;
        for my $perl_version (@perl_versions) {
            push @traces, Chart::Plotly::Trace::Bar->new(
                x => \@x,
                y => $series{$perl_version},
                name => $perl_version,
                error_y => {
                    type => 'data',
                    array => $series_error{$perl_version},
                    visible => 1,
                },
            );
        }
        my $plot = Chart::Plotly::Plot->new(
            traces => \@traces,
            layout => {
                barmode => 'group',
                title => "$test_name per second, by variation",
            },
        );
        $index .= Chart::Plotly::html_plot($plot);
    }
    {
        my @x = @perl_versions;
        my %series;
        my %series_error;
        for my $threaded (sort keys %$test) {
            for my $tainted (sort keys %{$test->{$threaded}}) {
                for my $perl_version (sort keys %{$test->{$threaded}{$tainted}}) {
                    push @{ $series{ "$threaded-$tainted" } }, $test->{$threaded}{$tainted}{$perl_version}{avg};
                    push @{ $series_error{ "$threaded-$tainted" } }, $test->{$threaded}{$tainted}{$perl_version}{stddev} * 2;
                }
            }
        }
        my @traces;
        for my $variation (sort keys %series) {
            push @traces, Chart::Plotly::Trace::Bar->new(
                x => \@x,
                y => $series{$variation},
                name => $variation,
                error_y => {
                    type => 'data',
                    array => $series_error{$variation},
                    visible => 1,
                },
            );
        }
        my $plot = Chart::Plotly::Plot->new(
            traces => \@traces,
            layout => {
                barmode => 'group',
                title => "$test_name per second, by perl version",
            },
        );
        $index .= Chart::Plotly::html_plot($plot);
    }
}
$index .= <<'END';
</body>
</html>
END
path("report/index.html")->spew_utf8($index);
