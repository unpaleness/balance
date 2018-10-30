#!/usr/bin/perl

use strict;
use warnings;

use CGI;
use SCS::DataBase;

my $cgi = CGI->new;
my $owner = $cgi->param('owner') || '.*';

my $base = SCS::DataBase->connect();
my $query = $base->prepare( qq{
    SELECT
        r1.storage AS storage,
        SUM(r1.value) AS balance
    FROM records AS r1
    WHERE owner REGEXP '^$owner\$'
    GROUP BY 1
} );
$query->execute();
my $table = '<table align="center">';
my $head = '<th>storage</th><th>balance</th>';
$table .= "<tr>$head</tr>";
my $sum = 0;
while ( my $row = $query->fetchrow_hashref() ) {
    $sum += $row->{balance};
    my $table_row = "<td>$row->{storage}</td>";
    $table_row .= '<td>' . ( $row->{balance} ? sprintf("%.2f", $row->{balance}) : '' ) . '</td>';
    $table .= "<tr>$table_row</tr>";
}
$table .= '<tr><td><b>Total</b></td><td><b>' . sprintf("%.2f", $sum) . '</b></td></tr>'
;
$table .= '</table>';

my $sample = qq{
<!DOCTYPE html>
<html>
    <head><title>Balance</title></head>
    <body>
        <h2 align="center">Current balance</h2>
        <div><font size="1">$table</font></div>
    </body>
</html>
};

print "Content-Type: text/html\n";
print $sample;

1;

