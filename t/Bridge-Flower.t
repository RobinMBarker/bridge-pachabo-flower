# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl Bridge-Flower.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 5;
BEGIN { use_ok('Bridge::Flower') };
BEGIN { use_ok('Bridge::Flower::JSON') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $distver = Bridge::Flower->VERSION;
ok($distver, 'Bridge::Flower->VERSION');

for my $pack (qw(Bridge::Flower::JSON)) {
    my $version = $pack->VERSION;
    ok($version, $pack .'->VERSION');
    cmp_ok($version, '<=', $distver, $pack .': version not greater than dist version');
}
