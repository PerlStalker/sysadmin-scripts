#!/usr/bin/env perl
use warnings;
use strict;

my $ceph = '/usr/bin/ceph';
my $pgs_to_keep = 10;

open (CEPH, '-|', "$ceph -w")
    or die "Can't open $ceph -w\n";

my @pgs;
my @remaining = ();
while (my $line = <CEPH>) {
    if ($line =~ m!(\d+)/\d+ objects degraded!) {
	my $remaining = $1;
	if (@pgs > $pgs_to_keep) {
	    shift @pgs;
	}
	if (@remaining > $pgs_to_keep) {
	    shift @remaining;
	}

	my $last;
	if (not @pgs) {
	    $last = 0;
	}
	else {
	    $last = $remaining[-1] - $remaining;
	}
	push @pgs, $last;
	push @remaining, $remaining;

	my $total = 0;
	for my $diff (@pgs) {
	    $total = $total + $diff;
	}
	my $avg_pgs = $total / @pgs; # pgs per second
	next if $avg_pgs == 0;
	my $mins_left = $remaining / ($avg_pgs * 60); # mins
	my $hrs_left = $mins_left / 60;
	#print "$remaining pgs / $last / $mins_left mins / $hrs_left hrs\n";
	printf("%d pgs / %3d / %0.2f avg / %0.2f mins / %0.2f hrs\n",
	       $remaining, $last, $avg_pgs, $mins_left, $hrs_left);
    }
}

close CEPH;
