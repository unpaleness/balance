package SCS::IniFile;

use Data::Dumper;
use Config::Simple;

sub read {
	my $self = shift;
	my $filename = shift;

	die "Error: .ini-file not specified" unless $filename;

	my %params;
	Config::Simple->import_from($filename, \%params);

	return \%params;
}

1;
