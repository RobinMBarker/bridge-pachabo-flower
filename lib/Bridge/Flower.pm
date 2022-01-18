package Bridge::Flower;

use strict;
use warnings;

use Pod::Usage;
use Getopt::Long(qw(:config posix_default no_ignore_case));
use List::Util qw(sum);

our $VERSION = '0.99';
our $gcd = eval { require Math::Utils } && Math::Utils->can('gcd');

sub main {
    my($pack) = @_;
    my $opts = $pack->getoptions;
     $opts->openout unless $opts->{stdout};
     $opts->set_rounds;
     $opts->set_name unless $opts->{name};
     $opts->total_boards;
     $opts->oppodata;
     $opts->eights if $opts->{eight};
     if ( $opts->{json} ) {
         $opts->writejson
     }
     else {
         $opts->writeout;
     }
     $opts->closeout unless $opts->{stdout};
}

sub getoptions {
    my $pack = shift;
    my($file, $force);
    GetOptions (
        '-h',   \my $help,
       '-v',    \my $version,
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
    if ( $version ) {
        warn "$0: $pack version ". $pack->VERSION ."\n";
        exit;
    }
    
    $stdout++ if ($file and $file eq '-');
    $json++ if $eight;

    $sessions = [ split /,/, $sessions ]
        if defined $sessions;
    my $total = $sessions ? sum @$sessions : 0;
    
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
    
    return bless {
        file    => $file,
        force   => $force,
        teams   => $teams, 
        ew_up   => $ew_up,
        total   => $total,
        boards  => $boards,
        name    => $name,
        stdout  => $stdout,   
        missing => $sitout_boards,
        miss_ew => $sitout_ew,
       sitout   => $sitout,
        json    => $json,
        eight   =>  $eight,
        sessions => $sessions,
    }, $pack;
} 

sub openout {
    my $self = shift;
    my $mode;
    if ( $self->{json} ) {
            $self->{file} //= 'config.json';
            $mode = '>';
    }
    else {
            $self->{file} //= 'TSUserMovements.txt';
            $mode = ($self->{force} ? '>' : '>>');
    }
    my $file = $self->{file};
    open STDOUT, $mode, $file or 
        die "Can't open $mode $file: $!\n";
}
        
sub set_rounds {
    my $self = shift;
    if( my $teams = $self->{teams} ) {
        $self->{sitout} = $teams % 2;
        $self->{rounds} = $teams;
        $self->{rounds}-- unless $self->{sitout};
    }
    else {
        $self->{sitout} //=(defined $self->{miss_ew} or
                            defined $self->{missing} );
        my $rounds = $self->{total};
        $rounds++ if $rounds % 2 == 0;
        $self->{teams} = $self->{rounds} = $rounds;
        $self->{teams}++ unless $self->{sitout};
    }
}

sub set_name {
    my $self = shift;
    if ( $self->{json} ) {
        $self->{name} = 'JSON'
    }
    else {
        require File::Basename;
        my $basename = File::Basename::fileparse($0, qr(\..*));
        $self->{name} = ucfirst $basename;  # Flower
    }
}
        
sub total_boards {
    my $self = shift;
    my $json = $self->{json};
    my $name = $self->{name};
    my $teams = $self->{teams};
    my $sitout = $self->{sitout};
    my $rounds = $self->{rounds};
    my $ew_up = $self->{ew_up};
    $ew_up = $self->{ew_up} =  $json ? 2 : $sitout ? 1 : 2
        unless $ew_up;
    my $boards = $self->{boards};
    $boards = $self->{boards} = $json ? 0 : int(100/$rounds+0.5) 
        unless $boards;
    warn "$name: teams = $teams; sitout = $sitout; rounds = $rounds; ".
        "EW-up = $ew_up; boards = $boards\n";
    if( $gcd ) { 
        die "Bad EW-up\n" unless 1 == $gcd->($ew_up, $rounds); 
    }
    
    if ( $sitout ) {
        unless ( $json ) {
            unless (defined $self->{missing} or 
                    defined $self->{miss_ew}) {
                $self->{missing} = 1;    # default to old behaviour
            }
            no warnings qw(uninitialized);
            warn    "At sitout table".
                    ": missing boards=$self->{missing}".
                    "; missing EW=$self->{miss_ew}\n"
        }
    }
    
    my $sessions = $self->{sessions} //= [];
    unshift @$sessions, ($rounds - $self->{total});
    warn "sessions = @$sessions\n";
    if ( $boards ) {
        my $total_boards = $rounds * $boards; 
        warn "total boards: $total_boards\n"; 
    }
}

sub oppodata {
    my $self = shift;
    my $ew_up = $self->{ew_up};
    my $teams = $self->{teams};
    my $rounds = $self->{rounds};
    my $sitout = $self->{sitout};
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
    $self->{oppodata} = \@oppodata;
}

sub eights {
        my $self = shift;
        my $teams = $self->{teams};
        for my $round (@{$self->{oppodata}}) {
            die unless $teams == scalar @$round;
            my @repeat = map {$_ + $teams} @$round;
            push @$round, @repeat;
        }
}

sub writejson {
        my $self = shift;
        require JSON;
        JSON->import(qw(to_json));
        my $assignments = to_json($self->{oppodata});
        $assignments =~ s/(\],)/$1\n/g;
        print $assignments,"\n";
}

sub writeout {
    my $self = shift;
    my $sessions = $self->{sessions};
    my $oppodata = $self->{oppodata};
    my $ew_up   = $self->{ew_up};
    my $teams   = $self->{teams};
    my $boards  = $self->{boards};
    my $sitout  = $self->{sitout};
    my $missing_boards  = $self->{missing};
    my $missing_ew      = $self->{miss_ew};
    my $sep = q(, );  # separator between (NS,EW,board-set) triples
    my $r = 0;
    for my $s (1 .. $#{$sessions}, 0) {
        my $session = $sessions->[$s];
        next unless $session > 0;
        my $head = $self->{name};
        $head .= sprintf " T%d: EW %+d", $teams, $ew_up;
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
            my $ew = $oppodata->[$r+$b-1][$ns-1];
            print $sep if $b > 1;
    
            my $board_set = $b;
            if ($ew == $ns) {
                if ($sitout) {
                    $ew = 0         if $missing_ew;
                    $board_set = 0  if $missing_boards;
                }
            }
            print "$ns,$ew,$board_set";
          }
          print "\n";
        }
        $r += $session;
    }
    warn "$r rounds: expected $self=>{rounds} rounds\n" 
        unless $r == $self->{rounds};
}

sub closeout {   
        my $self = shift;
        close STDOUT or die $!;
        warn "Movement written to $self->{file}\n";
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
