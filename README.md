# What?

A benchmark for perl taint/no-taint and threaded/not threaded

# How?

Using docker, on a Linux box:

```bash
# Prepare the repository:
perl ./dockerfiles.pl
./build.sh
# Run the images & produce report in bench.tsv:
make
# Analyze the report:
sort -rnk 4 < bench.tsv | column -t
```

# Better reports

Produce *multiple* `bench.tsv`, to average them out and show error bars.

Maybe run this on various machines, or on the same machine a number of times - doable by running `make -B`. Example:

```bash
mkdir -p reports
# Create the first report
make
# Save it / stash it away
cp bench.tsv reports/bench1.tsv
# Create anoher...
make -B
# Stash that away...
cp bench.tsv reports/bench2.tsv
# Yet another...
make -B
# and stash that one away, too:
cp bench.tsv reports/bench3.tsv
```

Once done, run `report.pl` to produce a report on `report/bench*.tsv` on averages, with error bars. The report will be available in `report/index.html`:

```bash
perl ./report.pl
$BROWSER report/index.html
```
