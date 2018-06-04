use strict;
use Getopt::Long(qw(:config posix_default no_ignore_case));
use List::Util qw(sum);

my($file, $force);
GetOptions ('-t=i', \my $teams, 
	'-ew=i', \my $ew_up,
	'-s=s', \my $sessions,
        '-b=i', \my $boards,
	'-n=s', \my $name,
	'',	\my $stdout,	# matches lone -
	'-f=s',    \$file,
	'-F=s', sub { (undef,$file) = @_; $force++; }
) or die;

warn "Ignored: @ARGV\n" if @ARGV;

$stdout++ if ($file and $file eq '-');
unless ($stdout) {
    $file = 'TSUserMovements.txt' unless $file;
    my $mode = ($force ? '>' : '>>');
    open STDOUT, $mode, $file or die "Can't open $mode $file: $!\n";
}
    
my @sessions;
@sessions = split /,/, $sessions if defined $sessions;
my $total = (sum @sessions) || 0;

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
die "Not enough data\n" unless $teams and $rounds;

unless ($name) {
    require File::Basename;
    $name = ucfirst (File::Basename::fileparse($0, qr(\.p.*)));
}
    
$ew_up = 2 - ($teams % 2) unless $ew_up;
$boards = int(110/$rounds) unless $boards;
warn "$name: teams = $teams; sitout = $sitout; rounds = $rounds; ".
	"EW up = $ew_up; boards = $boards\n";

unshift @sessions, ($rounds - $total);
warn "sessions = @sessions\n";

my $r = 0;
for my $s (1 .. $#sessions, 0) {
    my $session = $sessions[$s];
    next unless $session > 0;
    my $head = sprintf "%s T%d: EW %+d", $name, $teams, $ew_up;
    $head .= ": Session $s" if $s;
    $head .= ": Round";
    $head .= "s " . ($r + 1) . "-" if $session > 1;
    $head .= $r + $session;
    $head .= "\n";
    warn $head;

    print "\n";
    print $head;
    print "5,$teams,", $session * $boards, ",$boards,$session\n";

    my @rover;
    for my $ns (1 .. $rounds) {
      for my $b (1..$session) {
        my $ew = ($rounds + 1 - $ns + $ew_up * ($r + $b - 1)) % $rounds + 1;
        if ($ew == $ns and not $sitout) { $ew = $teams; $rover[$b]=$ns; }
        print "," if $b > 1;
        print "$ns,$ew,", ($ew == $ns ? 0 : $b);
      }
      print "\n";
    }
    unless( $sitout ) {
      for my $b (1..$session) {
        die unless $rover[$b];
        print "," if $b > 1;
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

