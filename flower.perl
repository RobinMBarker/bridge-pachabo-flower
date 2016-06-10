use strict;
use Getopt::Long;
use List::Util qw(sum max);

GetOptions ('-t=i', \my $teams, 
	'-ew=i', \my $ew_up,
	'-s=s', \my $sessions,
        '-b=i', \my $boards,
) or die;

my @sessions = split /,/, $sessions;

my $sitout;
my $rounds;
if( $teams ) {
    $sitout = $teams % 2;
    $rounds = $teams;
    $rounds-- unless $sitout;
}
else {
    $sitout = ($ew_up and $ew_up % 2);
    $rounds = sum @sessions;
    $rounds++ if $rounds % 2 == 0;
    $teams = $rounds;
    $teams++ unless $sitout;
}
$ew_up = 2 - ($teams % 2) unless $ew_up;
$boards = int(36 / (max @sessions)) unless $boards;
warn "teams = $teams; sitout = $sitout; rounds = $rounds; ".
	"EW up = $ew_up, boards = $boards\n";

push @sessions, ($rounds - (sum @sessions));

my $r = 0;
for my $s (1 .. $#sessions, 0) {
    my $session = $sessions[$s];
    next unless $session > 0;
    my $head = "Flower: EW ". sprintf "%+d", $ew_up;
    $head .= ": Session $s" if $s;
    $head .= ": Round";
    $head .= "s " . ($r + 1) . "-" if $session > 1;
    $head .= $r + $session;
    $head .= "\n";
    warn $head;

    print $head;
    print "5,28,", $session * $boards, ",$boards,$session\n";

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
    print "\n";
    $r += $session;
}
warn "$r rounds\n" unless $r == $rounds;


