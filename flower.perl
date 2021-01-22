use strict;
use Pod::Usage;
use Getopt::Long(qw(:config posix_default no_ignore_case));
use List::Util qw(sum);
use JSON;

my($file, $force);
GetOptions ('-h', \my $help,
	'-t=i', \my $teams, 
	'-ew=i', \my $ew_up,
	'',	\my $stdout,	# matches lone -
	'-f=s',    \$file,
	'-F:s', sub { (undef,$file) = @_; $force++; },
	'--missing-boards!',	\my $sitout_boards,
	'--missing-EW!',	\my $sitout_ew,
#    '--json', \my $json,
) or pod2usage(2);

pod2usage(1) if $help;

$stdout++ if ($file and $file eq '-');
unless ($stdout) {
    unless ( $file ) {    
        $file = 'config.json';
#       $file = $json ? 'config.json':'TSUserMovements.txt';
    }
    my $mode = ($force ? '>' : '>>');
    open STDOUT, $mode, $file or die "Can't open $mode $file: $!\n";
}
    
pod2usage ( 
	-message => "Not enough data",
	-verbose => 1,
	-output  => \*STDERR,
	-exitval => 2,
) unless $teams;


pod2usage ( 
	-message => "Ignored: @ARGV",
	-verbose => 0,
	-output  => \*STDERR,
	-exitval => q(NOEXIT),
) if @ARGV;

my $sitout = 0;
my $rounds;
if( $teams ) {
    $sitout = $teams % 2;
    $rounds = $teams;
    $rounds-- unless $sitout;
}
    
$ew_up = 2 - ($teams % 2) unless $ew_up;
warn "json: teams = $teams; sitout = $sitout; rounds = $rounds; ".
	"EW-up = $ew_up\n";

if ( $sitout ) {
    unless (defined $sitout_boards or defined $sitout_ew ) {
	$sitout_boards = 1; 	# default to old behaviour
    }
}

my @rounddata;
for my $r (1 .. $rounds) {
    my @data;
    my $rover;
    for my $ns (1 .. $rounds) {
        my $ew = ($rounds + 1 - $ns + $ew_up * ($r - 1)) % $rounds + 1;
        if ($ew == $ns) {
	        if ($sitout) {
		        $ew = 0 if $sitout_ew;
	        }
	        else { $ew = $teams; $rover=$ns; }
	    }
        push @data, $ew+0;
    }
    push @data, $rover if $rover;
    push @rounddata, \@data;
}

my $output = to_json(\@rounddata);
$output =~ s/(\],)/$1\n\t/g;
print $output,"\n";

unless ($stdout) {
    close STDOUT or die $!;
    warn "Movement written to $file\n";
}

__END__

=head1 NAME

flower.perl - create flower teams movements in JSS/EBUScore format

=head1 USAGE

perl -w flower.perl [-h] [-t num] [-ew num] [-s str] [-b num] [-n str]
[-] [-f file] [-F [file]] [--[no]missing-boards] [--[no]missing-EW] 

=head1 OPTIONS

=over 4

=item B<-h> 

Print this help

=item B<-t> num

Number of teams

=item B<-ew> num

Signed movement of EW pairs: +2 for 'up two', -1 for down 'one'

=item B<-s> string

Comma separated list of session lengths (rounds per session)

=item B<-b> num

Number of board per round: 

defaults to a complete movement of approx 100 boards

=item B<-n> name

Name of movement

=item B<->

Write to STDOUT

=item B<-f> file

Write to file: default 'TSUserMovements.txt'

=item B<-F> [file]

As B<-f> but start new file

Standalone B<-F> starts new 'TSUserMovements.txt'

=item B<--missing-EW> [B<--nomissing-EW>]

At the sitout table, show EW as 0

=item B<--missing-boards> [B<--nomissing-boards>]

At the sitout table, show board-set as 0

Default is B<--missing-boards>: but
B<--nomissing-boards>
will set both board-set and EW at sitout table.

=back

=cut



