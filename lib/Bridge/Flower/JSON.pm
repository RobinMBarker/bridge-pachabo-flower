package Bridge::Flower::JSON;

use strict;
use warnings;
use parent qw(Bridge::Flower);
use JSON qw(to_json);

our $VERSION = '1.35';

sub set_file {
    my $self = shift;
    $self->{file} = 'config.json';
}

sub set_name {
    my $self = shift;
    $self->{name} = 'JSON'
}

sub set_ew_up {
    my $self = shift;
    $self->{ew_up} = 2;
}

sub set_boards {
    my $self = shift;
    $self->{boards} = '';
}

sub set_missing {}

sub oppodata {
    my $self = shift;
    $self->SUPER::oppodata;
    $self->double if $self->{eight};
}

sub double {
        my $self = shift;
        my $teams = $self->{teams};
        for my $round (@{$self->{oppodata}}) {
            die unless $teams == scalar @$round;
            my @repeat = map {$_ + $teams} @$round;
            push @$round, @repeat;
        }
}

sub value {
        my $self = shift;
        my $assignments = to_json($self->{oppodata});
        $assignments =~ s/(\],)/$1\n/g;
        return $assignments;
}

sub key_value {
            my $self = shift;
            die if $self->{no_key};
            my $key = $self->{key};
            $key ||= 'match_assignments';
            my $tab = " "x $self->{indent};
            my $assignments = $self->value;
            $assignments =~ s/\A\[/\[\n/;
            $assignments =~ s/\]\z/\n$tab\]/;
            my $key_value = $tab.to_json($key)." : ".
                            $assignments;
            $key_value =~ s/^\[/$tab$tab\[/msg;
            return $key_value;
}

sub assignments {   
        my $self = shift;
        $self->{indent} //= 4;
        return $self->{no_key} ? $self->value
            : "{\n".  $self->key_value .  "\n}";
}

sub writeout { print shift()->assignments, "\n"; }

sub string {
    my($self, $data) = @_;
    return $self->make($data)->stringify;
}

sub make {
    my($pack, $data) = @_;
    my $self = bless $data, $pack;
    $self->set_rounds;
    $self->set_ew_up;
    $self->oppodata;
    return $self;
}

sub stringify {
    my $self = shift;
    $self->{indent} //= 2;
    return $self->{no_key}  ? $self->value 
                            : $self->key_value;
}

sub objectify { shift()->{oppodata} };

sub object {
    my($self, $data) = @_;
    return $self->make($data)->objectify;
}

1;

__END__

=head1 NAME

Bridge::Flower::JSON - Perl extension to Bridge::Flower for JSON output 

=head1 SYNOPSIS

  require Bridge::Flower::JSON;
  my $json_string = Bridge::Flower::JSON->string({teams=>8});

=head1 DESCRIPTION

JSON support for Bridge::Flower, 
to create flower teams movement as JSON match_assignment value;
by overriding some methods.

Can be used to produce JSON values using C<string> method.

=head2 SEE ALSO

Bridge::Flower

F<bin/flower>

=head2 METHODS

=over

=item set_file 

See Bridge::Flower

=item set_name 

See Bridge::Flower

=item set_ew_up 

See Bridge::Flower, set EW move to "up 2"

=item set_boards 

Set Bridge::Flower, C<boards> valuue not used

=item set_missing 

Not used

=item oppodata

Calculate movement data, 
including double movement

=item double 

Calculate double movement (for teams of eight)
from existing C<oppodata>

=item value 

String of movement data as JSON array

=item key_value 

String of movement data as JSON key-pair

=item assignments 

String of movement data as JSON object or array

=item writeout 

=item string(HASH)

Package method taking a HASH value (see OPTIONS)
and returning a string of movement data as
JSON value or key-value pair.

=item make(HASH) 

Package method taking a HASH value and
returning a Perl object containing movement data

=item object(HASH)

Package method taking a HASH value and
returning a Perl ARRAY of movement data

=item objectify

Return the ARRAY of movement data

=item stringify

Return a string of movement data as
JSON value or key-value pair

=back

=head2 OPTIONS

The HASH for the C<string>, C<object> and C<make> methods
has keys corresponding to C<bin/flower> options. 

=over

=item C<teams>: C<-t>

Number of team: required

=item C<eight>: C<-8>

Double movement, for teams of eight

=item C<key>: C<--key>

The key for the JSON key-value pair,
defaults to C<match_assignments>.

=item C<no_key>: missing C<--key> 

Output just the ARRAY value

=item C<indent>: C<--indent>

Indent for output string


=back

Other keys will be (at best) be ignored.

=head1 HISTORY

=over 

=item 1.00

2022-01-18 Robin Barker

Split from Bridge/Flower.pm

=item 1.10

2022-01-19 Robin Barker

Do not over-write JSON output file (unless -F)

=item 1.20

2022-01-20 Robin Barker

Write key:value JSON output

=item 1.30

2022-06-06 Robin Barker

Added methods: 
C<string>, 
C<value>, 
C<key_value>,
C<assignments>.

=item 1.35

2022-06-08 Robin Barker

Added methods:
C<make>,
C<object>,
C<objectify>,
C<stringify>

Reimplemented C<string> with C<make>

Implemented C<indent> option

=back

=head1 AUTHOR

Robin Barker r.m.barker@btinternet.com

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2022 by R. M. Barker

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.32.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
