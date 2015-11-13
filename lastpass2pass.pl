#!/usr/bin/perl
use warnings;
use strict;

use Text::CSV::Slurp;
use Data::Dumper;

# Top level directory to import into
my $top = 'LastPass';

# Change this if you want to name the pass entries something different
# from the CSV fields.
my %fieldmap = (
    url      => 'url',
    username => 'user',
    password => 'pass',
    extra    => 'extra',
    );

my $file = shift @ARGV;

# Need binary to deal with multi-line fields
my $data = Text::CSV::Slurp->load(file => $file,  binary => 1 );

# print STDERR Dumper $data->[21], "\n";

foreach my $entry (@{ $data }) {
    # print STDERR "Entry: ", Dumper $entry, "\n";
    foreach my $key (qw[ url username password extra ]) {
	if ($entry->{$key}) {
	    create_entry($entry, $key);
	}
    }
}

sub create_entry {
    my $entry = shift; # hash ref from Text::CSV::Slurp
    my $key   = shift; # username, password, etc.

    my $path = sprintf(
	'%s/%s/%s/%s',
	$top, $entry->{grouping}, $entry->{name},
	$fieldmap{$key} || $key
	);

    print STDERR "Creating $path\n";

    open (my $PASS, '|-', "pass insert -m '$path' > /dev/null")
	or die "Unable to insert into pass: $!\n";
    print $PASS $entry->{$key}, "\n";
    close $PASS;
}

__END__

=pod

=head1 SYNOPSIS

 lastpass2pass.pl lastpass.csv

=head1 DESCRIPTION

This takes the exported CSV from L<LastPass|http://lastpass.com> and
dumps the entries into the L<pass password
manager|http://www.passwordstore.org/>.

I like to break user name, password, url and extra into separate
entries for easy copy & paste. Edit C<%fieldmap> if you want to use
different entry names. If you want to do something different, edit
C<create_entry>.

This does import secure notes but does nothing to try and put
something sensible at the top of the entry to automatically copy for
you.

=cut
