package SCS::DataBase;

use DBI;

use SCS::IniFile;

sub connect {
	my $self = shift;
	my $suffix = shift || '';
	
	my $ini = SCS::IniFile->read("mysql.ini");
	my $database = $ini->{"client$suffix.database"};
	my $host     = $ini->{"client$suffix.host"};
	my $user     = $ini->{"client$suffix.user"};
	my $password = $ini->{"client$suffix.password"};
	die "Required parameters not found in ini-file" unless $database && $host && $user && $password;
	my $connection = DBI->connect("DBI:mysql:$database:$host", $user, $password);

	return $connection;
}

1;
