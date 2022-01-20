use strict;
use Test::More tests => 5;
use Bridge::JSON::File;

require_ok 'Bridge::Flower';

{
    my $warn;
    local $SIG{__WARN__} = sub { $warn .= $_[0] };
    require File::Temp;
    my $file = File::Temp->new( SUFFIX => '.json' )->filename;
    local @ARGV = (qw(--key -t 8 -f), $file);
    Bridge::Flower->main();
    ok( -e $file, 'flower --key' );
    like($warn,
        qr{^ Movement \s+ written \s+ to  
            \s+ \Q$file\E $}msx, 
       'flower --key - warning');

    my $got = Bridge::JSON::File->read_json($file);
    ok( defined $got, 'flower --key- output');
    my $expect = { match_assignments => [ [8,7,6,5,4,3,2,1],
    [3,8,1,7,6,5,4,2], [5,4,8,2,1,7,6,3], [7,6,5,8,3,2,1,4],
    [2,1,7,6,8,4,3,5], [4,3,2,1,7,8,5,6], [6,5,4,3,2,1,8,7] ] };
    is_deeply($got, $expect, 'flower --key - checked');
}
