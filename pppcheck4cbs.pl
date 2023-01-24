#!/usr/bin/perl
# Check PICA Patch Plain files to be applied to a CBS database
package PPPCheck4CBS;

use v5.14.1;
use PICA::Data qw(2.00 :all);

# Erlaubte Unterfelder, die nicht aus Expansion stammen
my %unexpanded = ( '045Q/01' => 'A' );

sub run {
    my $parser = pica_parser( plain => $_[0] );
    while ( my $rec = $parser->next ) {
        die "missing PPN\n" unless $rec->id;
        for ( @{ $rec->fields } ) {
            my $a = pica_annotation($_) or die "missing annotation\n";
            die "invalid annotation: $a\n" if $a !~ /^[ +-]$/;
            die "PPN must not be annotated\n"
              if $_->[0] eq '003@' and $a ne ' ';

       # TODO: wenn $8, dann entfernen (oder Fehler)
       # TODO: wenn $9 dann ansonsten nur erlaubte Unterfelder (sonst entfernen)
        }
    }
}

run(@ARGV) unless caller;

1;
