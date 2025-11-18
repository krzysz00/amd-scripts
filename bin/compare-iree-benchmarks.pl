#!/usr/bin/env perl
use warnings;
use strict;
use utf8;
use v5.30;

if (scalar @ARGV != 2) {
    die "Usage: $0 [old] [new]";
}

my %old_times;
my %new_times;
open(my $old_file, "<", $ARGV[0]) || die "Couldn't open old results ${ARGV[1]}";
open(my $new_file, "<", $ARGV[1]) || die "Couldn't open new results ${ARGV[2]}";

while (<$old_file>) {
    next unless /model_benchmark_run:model_benchmark_run.py:(\d+) (.+) benchmark time: ([0-9.]+) ms/;
    $old_times{$2} = $3;
}

while (<$new_file>) {
    next unless /model_benchmark_run:model_benchmark_run.py:(\d+) (.+) benchmark time: ([0-9.]+) ms/;
    $new_times{$2} = $3;
    die "Benchmark $2 not in old data" unless exists($old_times{$2});
}
die "Old benhmarks missing in new set" unless keys(%old_times) == keys(%new_times);

print("|Benchmark|Old time|New time|Speedup (old / new)|\n");
print("|------------|---------|-----------|--------------|\n");
foreach my $bench (keys %old_times) {
    my $old_time = $old_times{$bench} * 1.0;
    my $new_time = $new_times{$bench} * 1.0;
    printf("|$bench|%.2f|%.2f|%.2f|\n", $old_time, $new_time, $old_time / $new_time);
}
