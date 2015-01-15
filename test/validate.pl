#!/usr/bin/perl -w

use strict;

my $REDUNDANT_TITLE_CHECK = 0;

my @months_ok = qw(jan feb mar apr may jun jul aug sep oct nov dec {spring} {summer} {fall} {winter});
my %MONOK = map { $_ => 1; } @months_ok;
my %EXCEPT;

open(EXCEPTIONS, "exceptions");
while (<EXCEPTIONS>) {
  chomp;
  my ($name, $type) = split;
  $EXCEPT{$type}{$name} = 1;
}
close(EXCEPTIONS);

sub except {
  my ($name, $type) = @_;
  return 0 if !exists($EXCEPT{$type}{$name});
  return $EXCEPT{$type}{$name};
}

my ($type, $name, $month, $mon, $year, $title);

if (!$ARGV[0]) {
  die "Usage:  validate.pl <filename>\n";
}
open(IN, $ARGV[0]) || die "Could not open $ARGV[0]: $!\n";

my $errors = 0;
my %HAVE;
my %TITLES;
my %CTITLES;

while (<IN>) {
  if (/\s*@([A-Za-z0-9]+)\s*{\s*([^,]+),/i) {
#    print "Type:  $1  Name:  $2\n";
    $type = $1;
    $name = $2;
    if ($HAVE{$2}) {
      print "DUPLICATE ID: $2\n";
      $errors++;
    }
    $HAVE{$2}++;
  }
  if (/\s*mon\s*=\s*(.*),/) {
    print "Entry $name uses 'mon=' instead of 'month='\n";
    $errors++;
  }
  if (/^\s*title\s*=\s*(.*),/) {
    $title = $1;
    next if (!$REDUNDANT_TITLE_CHECK);
    next if ($type eq "proceedings");
    next if ($title =~ /personal\s*communication/i);
    $TITLES{$name} = $title;
    my $ctitle = $title;
    $ctitle =~ tr/A-Z/a-z/;
    $ctitle =~ s/[^a-zA-Z0-9]//g;
    if ($CTITLES{$ctitle}) {
      my $sim = $CTITLES{$ctitle};
      my $simtitle = $TITLES{$sim};
      print "Title for $name: $title\nclose to title for $sim: $simtitle\n";
      $errors++;
    } else {
      $CTITLES{$ctitle} = $name;
    }
  }

  if (/\s*month\s*=\s*(.*),/) {
    $month = $1;
    $mon = $month;
    $mon =~ tr/A-Z/a-z/;
    if ((!$MONOK{$mon}) && !except($name, "month")) {
       print "$name Month: $1\n" ;
       $errors++;
     }
  }
  if (/\s*year\s*=\s*(.*),/) {
    $year = $1;
    if ((!($year =~ /^[0-9][0-9][0-9][0-9]$/)) && !except($name, "year")) {
      print "$name Year: $year\n";
      $errors++;
    }
  }
  if (/\s*(volume|number)\s*=\s*(.*),/) {
    my $cat = $1;
    my $vol = $2;
    if ($vol =~ /{[0-9]+}/ && !except($name, "volume") && !except($name, "number")) {
      print "$name ${cat}: $vol  (don't protect only numeric values)\n";
      $errors++;
    }
  }
}

close(IN);

if ($errors) {
  die "$ARGV[0] failed validation.  $errors errors\n";
} else {
  print "$ARGV[0] passed validation!\n";
  exit(0);
}
