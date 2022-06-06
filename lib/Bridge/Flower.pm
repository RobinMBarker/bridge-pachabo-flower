package Bridge::Flower;

use strict;
use warnings;

use Pod::Usage;
use Getopt::Long(qw(:config posix_default no_ignore_case));
use List::Util qw(sum);

our $VERSION = '1.30';
our $gcd = eval { require Math::Utils } && Math::Utils->can('gcd');

sub main {
    my($pack) = @_;
    my $opts = $pack->getoptions;
     $opts->openout unless $opts->{stdout};
     $opts->set_rounds;
     $opts->set_name unless $opts->{name};
     $opts->set_ew_up unless $opts->{ew_up};
     $opts->set_boards unless $opts->{boards};
     $opts->total_boards;
     $opts->oppodata_eight;
     $opts->writeout;
     $opts->closeout unless $opts->{stdout};
}

sub JSON { __PACKAGE__.'::JSON'; }

# too much grief to call this sub 'require'
sub required {
    my($self,$pack) = @_;
    eval qq{ require $pack; } or die $@;
    return $pack;
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
        '-8',       \my $eight,
        '--key:s',  \my $key,
    ) or pod2usage(2);
    
    pod2usage(1) if $help;
    if ( $version ) {
        warn "$0: $pack version ". $pack->VERSION ."\n";
        exit;
    }
    
    $stdout++ if ($file and $file eq '-');
    my $no_key = not(defined $key);
    $json++ if $eight or !$no_key;

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
    
    my %missing = ( boards  => $sitout_boards,
                    EW      => $sitout_ew, );
    my $self = {
        file    => $file,
        force   => $force,
        teams   => $teams, 
        ew_up   => $ew_up,
        total   => $total,
        boards  => $boards,
        name    => $name,
        stdout  => $stdout,   
       sitout   => $sitout,
        eight   => $eight,
        key     => $key,
        no_key  => $no_key,
        sessions => $sessions,
    };
    while ( my($k,$v) = each %missing ) {
        $self->{missing}->{$k} = $v if defined $v;
    }
    
    $pack = $pack->required($pack->JSON) if $json;
    return bless $self, $pack;
} 

sub openout {
    my $self = shift;
    $self->set_file unless $self->{file};
    my $mode = $self->write ? '>' : '>>';
    my $file = $self->{file};
    open STDOUT, $mode, $file or 
        die "Can't open $mode $file: $!\n";
}

sub set_file {
    my $self = shift;
    $self->{file} = 'TSUserMovements.txt';
}

sub write { my $self = shift; return $self->{force}; }

sub set_rounds {
    my $self = shift;
    if( my $teams = $self->{teams} ) {
        $self->{sitout} = $teams % 2;
        $self->{rounds} = $teams;
        $self->{rounds}-- unless $self->{sitout};
    }
    else {
        $self->{sitout} //= exists $self->{missing};
        my $rounds = $self->{total};
        $rounds++ if $rounds % 2 == 0;
        $self->{teams} = $self->{rounds} = $rounds;
        $self->{teams}++ unless $self->{sitout};
    }
}

sub set_name {
        my $self = shift;
        require File::Basename;
        my $basename = File::Basename::fileparse($0, qr(\..*));
        $self->{name} = ucfirst $basename;  # Flower
}

sub set_ew_up {
    my $self = shift;
    $self->{ew_up} =  $self->{sitout} ? 1 : 2
}

sub set_boards {
    my $self = shift;
    $self->{boards} = int(100/$self->{rounds} + 0.5); 
}

sub total_boards {
    my $self = shift;
    my $name = $self->{name};
    my $teams = $self->{teams};
    my $sitout = $self->{sitout};
    my $rounds = $self->{rounds};
    my $ew_up = $self->{ew_up};
    my $boards = $self->{boards};
    
    warn "$name: teams = $teams; sitout = $sitout; rounds = $rounds; ".
        "EW-up = $ew_up; boards = $boards\n";
    if( $gcd ) { 
        die "Bad EW-up\n" unless 1 == $gcd->($ew_up, $rounds); 
    }
    
    $self->set_missing if $sitout;

    my $sessions = $self->{sessions} //= [];
    unshift @$sessions, ($rounds - $self->{total});
    warn "sessions = @$sessions\n";
    if ( $boards ) {
        my $total_boards = $rounds * $boards; 
        warn "total boards: $total_boards\n"; 
    }
}

sub set_missing {
    my $self = shift;
    $self->{missing}->{boards} = 1   
            # default to old behaviour
            unless exists $self->{missing};
    no warnings qw(uninitialized);
    warn    "At sitout table".
            ": missing boards=$self->{missing}->{boards}".
            "; missing EW=$self->{missing}->{EW}\n"
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

sub oppodata_eight {
    my $self = shift;
    $self->oppodata;
    $self->eights if $self->{eight};
}

sub writeout {
    my $self = shift;
    my $sessions = $self->{sessions};
    my $oppodata = $self->{oppodata};
    my $ew_up   = $self->{ew_up};
    my $teams   = $self->{teams};
    my $boards  = $self->{boards};
    my $sitout  = $self->{sitout};
    my $missing_boards  = $self->{missing}->{boards};
    my $missing_ew      = $self->{missing}->{EW};
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

=head1 NAMEH

Bridge::Flower - Perl extension  to implement the script flower.perl

=head1 SYNOPSIS

  use Bridge::Flower;
  main()

=head1 DESCRIPTION

Create flower teams movement.

=head2 SEE ALSO

F<bin/flower>

=head2 METHODS

=over

=item main 

Package method used by F<bin/flower>

=item JSON 

Package method to define subclass for JSON handling.

=item required(PACKAGE)

Require package (given as string - not bareword)

=item getoptions 

Package method to read options from C<@ARGV>
and return options as am object.

=item openout 

Open the output file for append or write.

=item set_file 

Set the default output file

=item write 

Returns true if output mode is write 
(rather than append)


=item set_rounds 

Process number of teams and number of rounds

=item set_name 

Set the default name of the movement

=item set_ew_up 

Set the EW pair movement

=item set_boards

Set the defaulber of boards, 
based on ~100 boards in the overall event.

=item total_boards 

Display the movement parameter and
calculate the total number of boards.

=item set_missing 

Return TRUE if there is a sitout.

=item oppodata 

Calculate the movement data

=item oppodata_eight 

Do C<oppodata> and C<eights>.

=item eights

(only defined for JSON)

=item writeout 

Write the output

=item closeout 

Close the output file

=back

=head1 HISTORY

=over 8

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

Moved code to modules

=item 1.00

2022-01-18 Robin Barker

Release

=item 1.10

See Bridge::Flower::JSON

=item 1.20 

2022-01-20 Robin Barker

Add --key to output JSON key-value

=item 1.30

2022-06-06 Robin Barker

Added C<no_key>, and other changes, to
facilitate C<< Bridge::Flower::JSON->string(HASH) >> 

=back

=head1 AUTHOR

Robin Barker r.n.barker@btinternet.com

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2022 by R. M. Barker

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.32.1 or,
at your option, any later version of Perl 5 you may have available.


=cut

