package Utils;


use base 'Exporter';
use YAML::Any qw(LoadFile);
our @EXPORT = qw(LoadYamlFile);
use strict;

sub LoadYamlFile {
    my $file = shift || '';
    die "\t File: $file doesn't exists" unless -f $file;
    return LoadFile($file);
}

1;