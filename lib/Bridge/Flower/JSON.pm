package Bridge::Flower::JSON;

use strict;
use warnings;
use parent qw(Bridge::Flower);

our $VERSION = '1.00';

sub set_file {
    my $self = shift;
    $self->{file} = 'config.json';
}

sub write { return 1 }

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
            die unless $tea::ms == scalar @$round;
            my @repeat = map {$_ + $teams} @$round;
            push @$round, @repeat;
        }
}

sub writeout {
        my $self = shift;
        require JSON;
        JSON->import(qw(to_json));
        my $assignments = to_json($self->{oppodata});
        $assignments =~ s/(\],)/$1\n/g;
        print $assignments,"\n";
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

=back

=head1 AUTHOR

Robin Barker r.n.barker@btinternet.com

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2022 by R. M. Barker

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.32.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
