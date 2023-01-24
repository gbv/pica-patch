use Test::More;
use Test::Exception;
use v5.14.1;

require "./pppcheck4cbs.pl";    ## no critic

*run = *PPPCheck4CBS::run;

throws_ok { run('t/pica.plain') } qr/missing annotation/;
throws_ok { run( \"  021A \$ax\n" ) } qr/missing PPN/;
throws_ok { run( \"  003@ \$01\n~ 021A \$ax\n" ) } qr/invalid annotation: ~/;
throws_ok { run( \"+ 003@ \$01\n" ) } qr/PPN must not be annotated/;

lives_ok { run('t/patch.plain') } 'valid patch';

done_testing;
