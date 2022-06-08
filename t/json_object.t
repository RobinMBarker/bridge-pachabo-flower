use strict;
use warnings;
use Test::More tests=>3;

require_ok 'Bridge::Flower::JSON';

{
    my $got =  Bridge::Flower::JSON->object({teams=>8});
    is_deeply($got, [
            [8,7,6,5,4,3,2,1],
            [3,8,1,7,6,5,4,2],
            [5,4,8,2,1,7,6,3],
            [7,6,5,8,3,2,1,4],
            [2,1,7,6,8,4,3,5],
            [4,3,2,1,7,8,5,6],
            [6,5,4,3,2,1,8,7]
        ],
        "json object");
}
{
    my $got =  Bridge::Flower::JSON->object({teams=>6, eight=>1});
    is_deeply($got, 
            [[6,5,4,3,2,1,12,11,10,9,8,7],
            [3,6,1,5,4,2,9,12,7,11,10,8],
            [5,4,6,2,1,3,11,10,12,8,7,9],
            [2,1,5,6,3,4,8,7,11,12,9,10],
            [4,3,2,1,6,5,10,9,8,7,12,11]
        ],
        "json object: eight");
}








