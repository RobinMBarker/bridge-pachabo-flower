package Bridge::Flower::JSON;

use strict;
use warnings;
use parent qw(Bridge::Flower);
use JSON qw(to_json);

our $VERSION = '1.30';

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

sub eights {
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
            my $tab = " "x4;
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
        my $assignments;
        if ( $self->{no_key} ) {
            $assignments = $self->value;
        }
        else {
            $assignments = "{\n".
                            $self->key_value .
                            "\n}";
        }
        $assignments .= "\n";
        return $assignments;
}

sub writeout { print shift()->assignments; }

sub string {
    my($self, $data) = @_;
    if (ref $self) {
        warn "Ignore data to $self->string()\n"
            if $data;
    }
    else {
        $data = {} unless $data;
        $self = bless $data, $self;
    }
    $self->set_rounds;
    $self->set_ew_up;
    $self->oppodata_eight;
    return $self->{no_key}  ? self->value 
                            : Eself->key_value;
}

1;

__END__

sub writeout { print shift()->assignments; }

sub string {
    my($self, $data) = @_;
    if (ref $self) {
        warn "Ignore data to $self->string()\n"
            if $data;
    }
    else {
        $data = {} unless $data;
        $self = bless $data, $self;
    }
    $self->set_rounds;
    $self->set_ew_up;
    $self->oppodata_eight;
    return $self->{no_key}  ? self->value 
                            : Eself->key_value;
}

1;

__END__

=head1 NAME

Bridge::Flower::JSON - Perl extension to implement JSON output from flower.perl

=head1 SYNOPSIS

  use Bridge::Flower;
  main()

Create flower teams movement as JSON match_assignment value.

=head2 SEE ALSO

Bridge::Flower

F<bin/flower>

=head1 HISTORY

=over 

=item 1.00

2022-01-18 Robin Barker

Split from Bridge/Flower.pm

=item 1.10

2022-01-19 Robin Barker

Do not over-write JSON output file (unless -F)

=item 1.20

Write key:value JSON output

=back

=head1 AUTHOR

Robin Barker r.m.barker@btinternet.com

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2022 by R. M. Barker

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.32.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
