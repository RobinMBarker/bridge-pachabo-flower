use strict;
use Test::More tests => 5;

BEGIN { 
    push @INC, -d 'blib' ? qw(blib/script) :
    do{ require Config;
        $Config::Config{installsitescript} 
    }
}

my $require_ok = eval { require q(flower); };

diag $INC{flower};
ok( $require_ok, 'flower.perl script' );

{
    my $warn;
    local $SIG{__WARN__} = sub { $warn .= $_[0] };
    require File::Temp;
    my $file = File::Temp->new( SUFFIX => '.json' )->filename;
    local @ARGV = qw(-t 13 --json -F);
    push @ARGV, $file;
    main();
    ok( -e $file, 'flower.perl' );
    like($warn, qr{^ Movement \s+ written \s+ to \s+ \Q$file\E $}msx, 'flower.perl - warning');

  SKIP: {
    eval q{require Bridge::JSON::File} or 
        skip 2, "No Bridge::JSON::File" ;

    my $json = Bridge::JSON::File->read_json($file);
    ok( defined $json, 'flower.perl - JSON output');
    my $expect = eval (do{ local $/; <DATA>}) or die;
    is_deeply($json, $expect, 'flower.perl - JSON checked');
  }
}


__DATA__
[[1,13,12,11,10,9,8,7,6,5,4,3,2],
[3,2,1,13,12,11,10,9,8,7,6,5,4],
[5,4,3,2,1,13,12,11,10,9,8,7,6],
[7,6,5,4,3,2,1,13,12,11,10,9,8],
[9,8,7,6,5,4,3,2,1,13,12,11,10],
[11,10,9,8,7,6,5,4,3,2,1,13,12],
[13,12,11,10,9,8,7,6,5,4,3,2,1],
[2,1,13,12,11,10,9,8,7,6,5,4,3],
[4,3,2,1,13,12,11,10,9,8,7,6,5],
[6,5,4,3,2,1,13,12,11,10,9,8,7],
[8,7,6,5,4,3,2,1,13,12,11,10,9],
[10,9,8,7,6,5,4,3,2,1,13,12,11],
[12,11,10,9,8,7,6,5,4,3,2,1,13]]
