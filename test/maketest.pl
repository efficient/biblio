#!/usr/bin/perl
while (<STDIN>) {
  if (/^@([a-zA-Z0-9]+){([^,\s]+),?/) {
    next if ($1 eq "proceedings");
    next if ($1 eq "string");
    print "\\cite{$2}\n";
  }
}
