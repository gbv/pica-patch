use Test::More;
use Test::Exception;
use v5.14.1;

require "./ppp4cbs.pl";    ## no critic

*run = *PPP4CBS::run;

throws_ok { run("t/pica.plain") } qr/missing annotation/;
throws_ok { run( \"  003@ \$01\n~ 021A \$ax\n" ) } qr/invalid annotation: ~/;
throws_ok { run( \"+ 003@ \$01\n" ) } qr/PPN must not be annotated/;
throws_ok { run( \"  003@ \$01\n" ) } qr/missing modification/;
throws_ok { run("t/linked.plain") } qr/offline expansion/;
throws_ok { run(qw(-e unexpand.txt t/expanded.plain)) } qr/offline expansion/;
throws_ok { run("t/linked.plain") } qr/offline expansion/;

lives_ok { run( \"  003@ \$01\n+ 021A \$92\n" ) } "linked record (\$9)";
lives_ok { run("t/patch.plain") } "valid patch";
lives_ok { run(qw(-e unexpand.txt t/linked.plain)) } "unexpanded subfields";

done_testing;
