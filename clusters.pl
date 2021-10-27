#!/usr/bin/perl -w

#
# see License.txt for copyright and terms of use
#

# compute a correlation matrix for a bunch of basic block observations 
# in the old many-files form

use strict;
use Cwd;
use File::Find;
use FindBin;
use lib $FindBin::Bin;
use trend_prof_common;
my $debugMode = -f "$FindBin::Bin/.debug";
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );

my ($dir) = @ARGV;
die $dir unless -d $dir;

opendir(DIR, $dir) or die "ERROR: can't open '$dir': $!";
while (my $entry = readdir(DIR)) {
    my $file = "$dir/$entry";
    next unless -f $file;
    # read zip file full of data points
    my $dataptsZip = Archive::Zip->new();
    $dataptsZip->read($file) == AZ_OK or die "ERROR: can't open '$file'";
    # read locations
    my @locs = $dataptsZip->memberNames();
    die unless @locs;
    # compute standard deviation of observations for each location
    my %nonzero;
    my %stddev;
    foreach my $loc (@locs) {
	next if $loc eq "total" || $loc eq "workload_sizes";
	my @ys = split(/\s+/, $dataptsZip->contents($loc));
	my $nz = 0;
	my $sum = 0;
	my $sumsq = 0;
	foreach my $y (@ys) {
	    if ($y > 0) {
		++$nz;  
		$sum += $y;
		$sumsq += $y * $y;
	    }
	}
	$nonzero{$loc} = $nz;
	$stddev{$loc} = $nz>1 ? ($nz * $sumsq - $sum * $sum) / ($nz * ($nz - 1)) : 0;
    }
    # we pick as representatives for clusters those blocks with large standard deviation;
    # we ignore bbs with small standard deviation;
    # intuitively, large stddev means more information and more interestingness
    my @worklistLocs = sort { $stddev{$b} <=> $stddev{$a} } (
	grep { ($_ ne "total") && ($_ ne "workload_sizes") && ($stddev{$_} > 10.0) } @locs );
    while (my $xloc = shift(@worklistLocs)) {
	next if $xloc eq "total" || $xloc eq "workload_sizes";
	die "'$xloc' contains a tab" if $xloc =~ m,\t,;
	my @xs = split(/\s+/, $dataptsZip->contents($xloc));
	die unless @xs;
	# find everything that correlates with it
	print $xloc;
	my @badlocs;
	foreach my $yloc (@worklistLocs) {
	    unless ($yloc eq "total" || $yloc eq "workload_sizes") {
                die "'$yloc' contains a tab" if $yloc =~ m,\t,;
                my @ys = split(/\s+/, $dataptsZip->contents($yloc));
                die unless @ys;
                my ($n, $coef0, $coef1, $rsq, @rest) = fit('linear', "$xloc:$yloc", \@xs, \@ys, 1);
                #my ($pn, $pcoef0, $pcoef1, $prsq, @prest) = fit('powerlaw', "$xloc:$yloc", \@xs, \@ys, 1);
                if (defined($rsq) && $rsq > 0.98) {
                    print "\t", $yloc;
                } else {
                    push(@badlocs, $yloc);
                }
            }
        } # foreach y
	print "\n";
	@worklistLocs = @badlocs;
    } # while (foreach x)
} # foreach file in dir
closedir(DIR) or die "ERROR: can't close '$dir': $!";

exit(0);

# TODO: WTF: quick sort example has compare fn in same cluster as linear fit
# why are they in the same cluster when the intercluster fit is terrible?
