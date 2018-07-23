#!/usr/bin/perl

use strict;
use warnings;

use SCS::DataBase;

my $base = SCS::DataBase->connect();
my $query = $base->prepare( qq{
    SELECT
        r1.storage AS storage,
        ROUND(SUM(r1.value), 2) AS balance
    FROM records AS r1
    GROUP BY 1
    UNION ALL
    SELECT
        "Total" AS storage,
        ROUND(SUM(r2.value), 2) AS balance
    FROM records AS r2
    ORDER BY 1
} );
$query->execute();
my $table = '<table>';
my $head = '<th>storage</th><th>balance</th>';
$table .= "<tr>$head</tr>";
while ( my $row = $query->fetchrow_hashref() ) {
    my $table_row = '<td>' . ( $row->{balance} ? sprintf("%.2f", $row->{balance}) : '' ) . '</td>';
    $table_row .= "<td>$row->{storage}</td>";
    $table .= "<tr>$table_row</tr>";
}
$table .= '</table>';

my $sample = qq{
<!DOCTYPE html>
<html>
    <head><title>Balance</title></head>
    <body>
        <h2>Current balance</h2>
        <div><font size="1">$table</font></div>
    </body>
</html>
};

print "Content-Type: text/html\n";
print $sample;

1;

