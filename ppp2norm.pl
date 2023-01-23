#!/usr/bin/perl
# Convert from PICA Patch Plain to PICA Patch Normalized
use v5.14.1;
while (<>) {
    say && next if $_ eq '';    # end of record
    die "invalid PICA Patch Plain at line $.: '$_'\n"
      if $_ !~ qr{^([ +-]) ([012]\d\d[A-Z@](/\d+)?) \$(.+)};
    my $value = join '$', map { s/\$/\x1F/gr; } split '\$\$', $4;
    print "$2$1\x1F$value\x1E";
}
