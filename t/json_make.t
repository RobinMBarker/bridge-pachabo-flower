use strict;
use warnings;
use JSON;
use Test::More tests=>4;

require_ok 'Bridge::Flower::JSON';

my $expect8 = [
            [8,7,6,5,4,3,2,1],
            [3,8,1,7,6,5,4,2],
            [5,4,8,2,1,7,6,3],
            [7,6,5,8,3,2,1,4],
            [2,1,7,6,8,4,3,5],
            [4,3,2,1,7,8,5,6],
            [6,5,4,3,2,1,8,7] ];

{
    my $got =  Bridge::Flower::JSON->make({teams=>8});
    ok($got, 'json make');
    is_deeply($got->objectify, $expect8,
        "json make: object");

    my $json = from_json('{' . $got->stringify .'}');
    is_deeply($json, {match_assignments => $expect8},
        "json make: string");
}








