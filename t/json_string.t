use strict;
use warnings;
use JSON;
use Test::More tests=>8;

require_ok 'Bridge::Flower::JSON';

{
    my $got = Bridge::Flower::JSON->string({teams=>8});
    like($got,qr{\A\s+"match_assignments"\s*:\s*\[},
        "string: teams=>8");
}
{
    my $got =  Bridge::Flower::JSON->string({teams=>8, no_key=>1});
    ok($got, "string: no_key");
    my $json = from_json $got;
    is_deeply($json, [
            [8,7,6,5,4,3,2,1],
            [3,8,1,7,6,5,4,2],
            [5,4,8,2,1,7,6,3],
            [7,6,5,8,3,2,1,4],
            [2,1,7,6,8,4,3,5],
            [4,3,2,1,7,8,5,6],
            [6,5,4,3,2,1,8,7]
        ],
        "string: no_key: json OK");
}
{
    my $got =  Bridge::Flower::JSON->string({teams=>7, key=>"xyzzy"});
    ok($got, "string: key");
    my $json = from_json "{".$got."}";
    is_deeply($json, { xyzzy => [
            [1,7,6,5,4,3,2],
            [3,2,1,7,6,5,4],
            [5,4,3,2,1,7,6],
            [7,6,5,4,3,2,1],
            [2,1,7,6,5,4,3],
            [4,3,2,1,7,6,5],
            [6,5,4,3,2,1,7]
          ]
        },
        "string: key: json OK");
}
{
    my $got =  Bridge::Flower::JSON->string({teams=>6, eight=>1});
    ok($got, "string: eight");
    my $json = from_json "{".$got."}";
    is_deeply($json, { match_assignments => 
            [[6,5,4,3,2,1,12,11,10,9,8,7],
            [3,6,1,5,4,2,9,12,7,11,10,8],
            [5,4,6,2,1,3,11,10,12,8,7,9],
            [2,1,5,6,3,4,8,7,11,12,9,10],
            [4,3,2,1,6,5,10,9,8,7,12,11]]
        },
        "string: eight: json OK");
}








