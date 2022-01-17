package Bridge::Flower;

use strict;
use warnings;
use parent qw( Exporter);

our @EXPORT = qw( main );
our $VERSION = '0.99';

use Pod::Usage;
use Getopt::Long(qw(:config posix_default no_ignore_case));
use List::Util qw(sum);

sub main {
my $gcd = eval { require Math::Utils } && Math::Utils->can('gcd');
    
    my($file, $force);
    GetOptions ('-h', \my $help,
        '-t=i', \my $teams, 
        '-ew=i', \my $ew_up,
        '-s=s', \my $sessions,
        '-b=i', \my $boards,
        '-n=s', \my $name,
        '',     \my $stdout,    # matches lone -
        '-f=s', \$file,
        '-F:s', sub { (undef,$file) = @_; $force++; },
        '--missing-boards!', \my $sitout_boards,
        '--missing-EW!', \my $sitout_ew,
        '--sitout', \my $sitout,
        '--json',   \my $json,
        '-8',   \my $eight,
    ) or pod2usage(2);
    
    pod2usage(1) if $help;
    
    $stdout++ if ($file and $file eq '-');
    $json++ if $eight;
    unless ($stdout) {
        my $mode;
        if ( $json ) {
            $file = 'config.json' unless $file;
            $mode = '>';
        }
        else {
            $file = 'TSUserMovements.txt' unless $file;
            $mode = ($force ? '>' : '>>');
        }
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
        -message => "Even number of teams: no sitout",
        -verbose => 1,
        -output  => \*STDERR,
        -exitval => 2,
    ) if ($teams and ($teams % 2 == 0) and $sitout);
    
    pod2usage ( 
        -message => "Ignored: @ARGV",
        -verbose => 0,
        -output  => \*STDERR,
        -exitval => q(NOEXIT),
    ) if @ARGV;
    
    my $rounds;
    if( $teams ) {
        $sitout = $teams % 2;
        $rounds = $teams;
        $rounds-- unless $sitout;
    }
    else {
        $sitout //= (defined $sitout_ew or defined $sitout_boards);
        $rounds = $total;
        $rounds++ if $rounds % 2 == 0;
        $teams = $rounds;
        $teams++ unless $sitout;
    }
    
    unless ($name) {
      if ( $json ) {
        $name = 'JSON'
      }
      else {
        require File::Basename;
        $name = ucfirst (File::Basename::fileparse($0, qr(\.p.*)));
      }
    }
        
    $ew_up = $json ? 2 : $sitout ? 1 : 2 unless $ew_up;
    $boards = $json ? 0 : int(100/$rounds+0.5) unless $boards;
    warn "$name: teams = $teams; sitout = $sitout; rounds = $rounds; ".
        "EW-up = $ew_up; boards = $boards\n";
    if( $gcd ) { 
        die "Bad EW-up\n" unless 1 == $gcd->($ew_up, $rounds); 
    }
    
    if ( $sitout ) {
      unless ( $json ) {
        unless (defined $sitout_boards or defined $sitout_ew ) {
            $sitout_boards = 1;     # default to old behaviour
        }
        no warnings qw(uninitialized);
        warn "At sitout table".
        ": missing boards=$sitout_boards".
        "; missing EW=$sitout_ew\n"
      }
    }
    
    unshift @sessions, ($rounds - $total);
    warn "sessions = @sessions\n";
    if ( $boards ) {
        my $total_boards = $rounds * $boards; 
        warn "total boards: $total_boards\n"; 
    }
    
    my @oppodata;
    for my $r (1 .. $rounds) {
        my $rover;
        my @oppo;
        for my $t (1 .. $rounds) {
            my $v = ($rounds + 1 - $t + $ew_up * ($r - 1)) % $rounds + 1;
            if ( $v == $t ) {
                unless ( $sitout ) { $v = $teams+0; $rover = $t; }
            }
            push @oppo, $v;
        }
        push @oppo, $rover unless $sitout;
        push @oppodata, \@oppo;
    }
    
    if ( $eight ) {
        for my $round (@oppodata) {
            die unless $teams == scalar @$round;
            my @repeat = map {$_ + $teams} @$round;
            push @$round, @repeat;
        }
    }
    
    if ( $json ) {
        require JSON;
        JSON->import(qw(to_json));
        my $assignments = to_json(\@oppodata);
        $assignments =~ s/(\],)/$1\n/g;
        print $assignments,"\n";
    }
    else {        
      my $sep = q(, );  # separator between (NS,EW,board-set) triples
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
        
        for my $ns (1 .. $teams) {
          for my $b (1..$session) {
            my $ew = $oppodata[$r+$b-1][$ns-1];
            print $sep if $b > 1;
    
            my $board_set = $b;
            if ($ew == $ns) {
                if ($sitout) {
                    $ew = 0 if $sitout_ew;
                    $board_set = 0 if $sitout_boards; 
                }
            }
            print "$ns,$ew,$board_set";
          }
          print "\n";
        }
        $r += $session;
      }
      warn "$r rounds: expected $rounds rounds\n" unless $r == $rounds;
    }
    
    unless ($stdout) {
        close STDOUT or die $!;
        warn "Movement written to $file\n";
    }

}

1;

__END__

=head1 NAME

Bridge::Flower - Perl extension  to implement the script flower.perl

=head1 SYNOPSIS

  use Bridge::Flower;
  main()

Create flower teams movement.

=head2 SEE ALSO

F<bin/flower>

=head2 EXPORT

main()

=head1 HISTORY

=over 8
o
=item Pre-history

F<flower.perl> was created in 2015 to produce
EBUScore=Teams movement files, when the Pachabo Cup
movement changed to teams having home tables.

In Janury 2021, the facility to create JSON files
for RealBridge config files,
for the online National Point-a-Board Teams.

=item 0.01

Original version; created by h2xs 1.23 with options

  -XACn
	Bridge::Flower

Renamed F<flower.perl> as F<bin/flower>

=item 0.99

2022-01-17 Robin Barker

=back

=head1 AUTHOR

Robin Barker r.n.barker@btinternet.com

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2022 by R. M. Barker

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.32.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
