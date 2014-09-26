#!/usr/bin/perl
use warnings;
use strict;

# put in /usr/lib/check_mk_agent/local
# Works with firefly
## check_mk local ceph check

my $ceph = '/usr/bin/ceph';

my %status = (
    OK   => 0,
    WARN => 1,
    CRIT => 2,
    UNKNOWN => 3
    );

open my $ceph_fh, "-|", "$ceph -s"
    or die "can't run $ceph -s\n";

my $rc = $status{UNKNOWN};
my $health = '';
my $error = '';
my %perf_data = (
    data => { value => 0, units => 'B' },
    used => { value => 0, units => 'B' },
    avail => { value => 0, units => 'B' },
    total => { value => 0, units => 'B' },
    reads => { value => 0, units => 'B' },
    writes => { value => 0, units => 'B' },
    ops => 0
    );

while (my $line = <$ceph_fh>) {
    #print "$line";
    chomp $line;
    if ($line =~ /^\s*health\s+(\w+)\s*(.*)/) {
	$health = $1;
	if    ($1 eq 'HEALTH_OK')   { $rc = $status{OK}; }
	elsif ($1 eq 'HEALTH_WARN') { $rc = $status{WARN}; }
	elsif ($1 eq 'HEALTH_ERR')  { $rc = $status{CRIT}; }
	else                        { $rc = $status{UNKNOWN}; }

	$error = $2;
    }
    elsif ($line =~ /^\s*monmap\s+/) {
    }
    elsif ($line =~ /^\s*osdmap\s+/) {
    }
    elsif ($line =~ /^\s*pgmap\s.*?: (\d+) pgs: (.*)/) {
	my $pgs_total = $1;
	my @stats = split ';', $2;
	## stats[0] is the ative+clean, etc stats
	# skip for now

	## stats[1] is the disk used
	#print "Stats 1: $stats[1]\n";
	if ($stats[1] =~ m{\s*(\d+) (\S+) data, (\d+) (\S+) used, (\d+) (\S+) / (\d+) (\S+) avail}) {
	    $perf_data{data}{value} = $1;
	    $perf_data{data}{units} = $2;
	    $perf_data{used}{value} = $3;
	    $perf_data{used}{units} = $4;
	    $perf_data{avail}{value} = $5;
	    $perf_data{avail}{units} = $6;
	    $perf_data{total}{value} = $7;
	    $perf_data{total}{units} = $8;
	}

	## stats[2] is the writes, ops/s
	#print "Stats 2: $stats[2]\n";
	if ($stats[2] =~ m{^\s*(\d+)(\w?B)/s wr, (\d+)op/s}) {
	    $perf_data{writes}{value} = $1;
	    $perf_data{writes}{units} = $2;
	    if ($perf_data{writes}{units} eq 'KB') {
		$perf_data{writes}{value} *= 1024;
	    }
	    elsif ($perf_data{writes}{units} eq 'MB') {
		$perf_data{writes}{value} *= 1024**2;
	    }
	    $perf_data{writes}{units} = 'B';
	    $perf_data{ops} = $3;
	}
    }
    elsif ($line =~ /^\s*client io (.*)/) {
	my $stats = $1;	
	if ($stats =~ m!(\d+) (.?B)/s rd, (\d+) (.?B)/s wr, (\d+) op/s!) {
	    $perf_data{reads}{value} = $1;
	    $perf_data{reads}{units} = $2;
	    $perf_data{writes}{value} = $3;
	    $perf_data{writes}{units} = $4;
	    $perf_data{ops} = $5;

	    if ($perf_data{reads}{units} =~ /KB/i) {
		$perf_data{reads}{value} *= 1024;
	    }
	    elsif ($perf_data{reads}{units} =~ /MB/i) {
		$perf_data{reads}{value} *= 1024**2;
	    }
	    $perf_data{reads}{units} = 'B';

	    if ($perf_data{writes}{units} =~ /KB/i) {
		$perf_data{writes}{value} *= 1024;
	    }
	    elsif ($perf_data{writes}{units} =~ /MB/i) {
		$perf_data{writes}{value} *= 1024**2;
	    }
	    $perf_data{writes}{units} = 'B';
	}
    }
    elsif ($line =~ /^\s*mdsmap\s*/) {
    }
}

close $ceph_fh;

#use Data::Dumper; print Dumper \%perf_data;

## Check check
print "$rc ceph_health - $health: $error\n";

## data used
# TODO warn on avail <= 15%; crit on <= 5%
print "$status{OK} ceph_data ";
print "'data'=$perf_data{data}{value}$perf_data{data}{units}";
print "|'used'=$perf_data{used}{value}$perf_data{used}{units}";
print "|'avail'=$perf_data{avail}{value}$perf_data{avail}{units}";
print "|'total'=$perf_data{total}{value}$perf_data{total}{units}";
print " $health - $perf_data{avail}{value} $perf_data{avail}{units} / $perf_data{total}{value} $perf_data{total}{units} avail";
print "\n";

## throughput
print "$status{OK} ceph_throughput ";
print "'rd/s'=$perf_data{reads}{value}$perf_data{reads}{units}";
print "|'wr/s'=$perf_data{writes}{value}$perf_data{writes}{units}";
print "|'op/s'=$perf_data{ops}";
print " $perf_data{reads}{value}$perf_data{reads}{units} rd, $perf_data{writes}{value}$perf_data{writes}{units} wr, $perf_data{ops} op/s";
print "\n";

exit;
