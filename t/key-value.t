use strict;
use Test::More tests => 5;

require_ok 'Bridge::Flower';

{
    my $warn;
    local $SIG{__WARN__} = sub { $warn .= $_[0] };
    require File::Temp;
    my $file = File::Temp->new( SUFFIX => '.json' )->filename;
    local @ARGV = (qw(--key wibble -t 25 -F), $file);
    Bridge::Flower->main();
    ok( -e $file, 'flower --key=string' );
    like($warn,
        qr{^ Movement \s+ written \s+ to  
            \s+ \Q$file\E $}msx, 
       'flower --key=string - warning');

SKIP: {
    eval q{require Bridge::JSON::File} or
        skip "No Bridge::JSON::File", 2;

    my $got = Bridge::JSON::File->read_json($file);
    ok( defined $got, 'flower --key=string- output');
    is_deeply([keys %$got], [qw(wibble)],
            'flower --key=string - checked');
  }
}
