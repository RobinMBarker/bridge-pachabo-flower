use strict;
use Pod::Usage;
use Getopt::Long(qw(:config posix_default no_ignore_case));
use List::Util qw(sum);

my($file, $force);
GetOptions ('-h', \my $help,
	'-t=i', \my $teams, 
	'-ew=i', \my $ew_up,
	'-s=s', \my $sessions,
        '-b=i', \my $boards,
	'-n=s', \my $name,
	'',	\my $stdout,	# matches lone -
	'-f=s',    \$file,
	'-F:s', sub { (undef,$file) = @_; $force++; },
	'--missing-boards!',	\my $sitout_boards,
	'--missing-EW!',	\my $sitout_ew,
) or pod2usage(2);

pod2usage(1) if $help;

$stdout++ if ($file and $file eq '-');
unless ($stdout) {
    $file = 'TSUserMovements.txt' unless $file;
    my $mode = ($force ? '>' : '>>');
    open STDOUT, $mode, $file or die "Can't open $mode $file: $!\n";
}
    
my @sessions;
@sessions = split /,/, $sessions if defined $sessions;
my $total = (sum @sessions) || 0;

pod2usage ( 
	-message => "Not enough data",
	-verbose => 1,
	-output  => \*STDERR,
	-exitval => 2,
) unless ($teams or $total > 0);


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
else {
    $sitout = $ew_up % 2 if $ew_up;
    $rounds = $total;
    $rounds++ if $rounds % 2 == 0;
    $teams = $rounds;
    $teams++ unless $sitout;
}

unless ($name) {
    require File::Basename;
    $name = ucfirst (File::Basename::fileparse($0, qr(\.p.*)));
}
    
$ew_up = 2 - ($teams % 2) unless $ew_up;
$boards = int(100/$rounds+0.5) unless $boards;
warn "$name: teams = $teams; sitout = $sitout; rounds = $rounds; ".
	"EW-up = $ew_up; boards = $boards\n";

if ( $sitout ) {
    unless (defined $sitout_boards or defined $sitout_ew ) {
	$sitout_boards = 1; 	# default to old behaviour
    }
    no warnings qw(uninitialized);
    warn "At sitout table".
	": missing boards=$sitout_boards".
	"; missing EW=$sitout_ew\n"
}

unshift @sessions, ($rounds - $total);
warn "sessions = @sessions\n";
{ my $total_boards = $rounds * $boards; 
  warn "total boards: $total_boards\n"; 
}

my $r = 0;
for my $s (1 .. $#sessions, 0) {
    my $session = $sessions[$s];
    next unless $session > 0;
    my $head = sprintf "%s T%d: EW %+d", $name, $teams, $ew_up;
    $head .= ": Session $s" if $s;
    $head .= ": Round";
    $head .= "s" if $session > 1;
    $head .= " ". ($r + 1);
    $head .= "-". ($r + $session) if $session > 1;
    $head .= "\n";
    warn $head;

    print "\n";
    print $head;
    print "5,$teams,", $session * $boards, ",$boards,$session\n";

    my $sep = q(, );	# separator between (NS,EW,board-set) triples
    my @rover;
    for my $ns (1 .. $rounds) {
      for my $b (1..$session) {
        my $ew = ($rounds + 1 - $ns + $ew_up * ($r + $b - 1)) % $rounds + 1;
        print $sep if $b > 1;

	my $board_set = $b;
        if ($ew == $ns) {
	    if ($sitout) {
		$ew = 0 if $sitout_ew;
		$board_set = 0 if $sitout_boards; 
	    }
	    else { $ew = $teams; $rover[$b]=$ns; }
	}
        print "$ns,$ew,$board_set";
      }
      print "\n";
    }
    unless( $sitout ) {
      for my $b (1..$session) {
        die unless $rover[$b];
        print $sep if $b > 1;
        print "$teams,$rover[$b],$b";
      }
      print "\n";
    }
    $r += $session;
}
warn "$r rounds: expected $rounds rounds\n" unless $r == $rounds;

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



