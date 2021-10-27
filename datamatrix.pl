#!/usr/bin/perl -w

#
# see License.txt for copyright and terms of use
#

use strict;
use File::Find;
use FindBin;
use lib $FindBin::Bin;
use trend_prof_common;
my $debugMode = -f "$FindBin::Bin/.debug";
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );

my ($infile) = @ARGV;
die $infile unless -f $infile;

my $dataptsZip = Archive::Zip->new();
$dataptsZip->read($infile) == AZ_OK or die "ERROR: can't open '$infile'";
# read sizes
my @sizes = split("\t", $dataptsZip->contents("workload_sizes"));
if (!@sizes) {
    die "STRANGE ERROR: $infile does not contain a 'workload_sizes' entry." if $debugMode;
    next;
} 
my @locs = $dataptsZip->memberNames();
open(LOCS, '>', "locs") or die "$!";
print LOCS (join("\n", @locs));
close(LOCS) or die $!;

open(PTS, '>', "pts") or die $!;
foreach my $loc (@locs) {
    #next if "workload_sizes" eq $loc;
    #my @ys = split(/\s+/, $dataptsZip->contents($loc));
    my $ys = $dataptsZip->contents($loc);
    print PTS $ys, "\n";
}
close(PTS) or die $!;
