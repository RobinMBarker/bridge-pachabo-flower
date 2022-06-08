use strict;
use warnings;
use Test::More tests=>2;

require_ok 'Bridge::Flower';



open my $fh , '>', \my $buffer;
{ 
    local @ARGV = qw(-key -t 4 -i 3 -);
# local $SIG{__WARN__} = sub { diag @_ };
    local $SIG{__WARN__} = sub { 1 };
    select $fh;
    Bridge::Flower->main;
    select;
}
close $fh or die;
my $line = qr{ \s{6} \[ \d (, \s* \d)* \] }x;
like( $buffer, qr{ \A \{ \n 
            \s{3} "match_assignments"
                \s* \: \s* \[ \n
            $line (, \n $line )* \n
            \s{3} \] \n
            \} \Z
        }x,
    'JSON -i 3: output');
__END__
            
            \} \z


