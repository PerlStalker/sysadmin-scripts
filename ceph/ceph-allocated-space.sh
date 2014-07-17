#!/bin/bash
POOL=${1-kvm_prod}
rbd ls -p $POOL -l | perl -ne '@info = split " "; if ($info[1] =~ /(\d+)M/ ) { $t += $1 } elsif ($info[1] =~ /(\d+)G/ ) { $t += 1024*$1; }; print("$info[0]\t", $info[1], "\t", $t / 1024.0, "G\n");'
