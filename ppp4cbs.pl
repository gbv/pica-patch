#!/usr/bin/env perl
package PPP4CBS;

use v5.14.1;
use PICA::Data   qw(2.00 :all);
use Getopt::Long qw(GetOptionsFromArray);
use Pod::Usage;
use open qw/:std :utf8/;
use autodie;

sub expansion {
    my @unexpand;

    open( my $fh, "<", $_[0] );
    for (<$fh>) {
        next if $_ =~ /^\s*(#.*)?$/;
        $_ =~ /^\s*([0-9A-Z@\/]+)\s+([a-zA-Z0-9]+)\s*$/
          or die "error in unexpansion file: $_\n";
        push @unexpand, { field => pica_path($1), codes => qr/[$2]/ };
    }
    close $fh;

    return \@unexpand;
}

sub run {
    GetOptionsFromArray( \@_, \my %opt, "help|?", "expansion|e:s" )
      or pod2usage(2);
    pod2usage(1) if $opt{help};

    my $unexpand = $opt{expansion} ? expansion( $opt{expansion} ) : [];

    my $parser = pica_parser( plain => $_[0], strict => 1 );

    my $n = 1;
    while ( my $rec = $parser->next ) {
        my $modify;
        for my $field ( @{ $rec->fields } ) {

            my $a = pica_annotation($field) or die "$n: missing annotation\n";

            die "$n: invalid annotation: $a\n" if $a !~ /^[ +-]$/;
            $modify ||= $a =~ /[+-]/;

            die "$n: PPN must not be annotated\n"
              if $field->[0] eq '003@' and $a ne ' ';

            die "$n: detected offline expansion of linked record (\$9)\n"
              if expanded_subfields( $field, $unexpand );
        }
        die "$n: missing modification (+/-) in record" unless $modify;
        $n++;
    }

    say $n - 1 . " PICA Patch records ok";
}

sub expanded_subfields {
    my ( $field, $unexpand ) = @_;

    # TODO: introduce fields object in PICA::Data to simplify this:
    my @codes =
      map { $field->[ 2 * $_ - 2 ] } 2 .. ( scalar @$field / 2 );
    if ( @codes > 1 && grep { $_ eq '9' } @codes ) {
        for my $check (@$unexpand) {
            if ( $check->{field}->match_field($field) ) {
                return !!( grep { $_ ne '9' && $_ !~ $check->{codes} } @codes );
                last;
            }
        }
        return 1;
    }
}

run(@ARGV) unless caller;

1;

__END__

=head1 NAME


=head1 SYNOPSIS

ppp4cbs [options] [files...]

Checks PICA Patch records to be applied in CBS database.

=head1 OPTIONS

=over 4

=item B<--help>

Print this help message.

=item B<--expansion> file

Provide a file with allowed subfields in expanded fields.

=cut
