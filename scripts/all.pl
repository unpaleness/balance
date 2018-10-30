#!/usr/bin/perl

use strict;
use warnings;

use CGI;
use SCS::DataBase;

my $cgi = CGI->new;
my $owner = $cgi->param('owner') || '.*';

my $color_positive = ' bgcolor="#88ff88"';
my $color_negative = ' bgcolor="#ff8888"';
my $color_zero = ' bgcolor="#ffff88"';

my $base = SCS::DataBase->connect();
my $query = $base->prepare( "SELECT DISTINCT storage FROM records WHERE owner REGEXP '^$owner\$' ORDER BY 1" );
$query->execute();
my @storages = ();
my $diffs = {};
my $totals = {};
while ( my $row = $query->fetchrow_hashref() ) {
    push @storages, $row->{storage};
    $diffs->{ $row->{storage} } = 0;
    $totals->{ $row->{storage} } = 0;
}
$diffs->{total} = 0;
$totals->{total} = 0;

$query = $base->prepare( qq|
    SELECT r.id, r.date, r.type, r.title, r.storage, r.value
    FROM records AS r
    WHERE owner REGEXP '^$owner\$'
    ORDER BY 2, 1
| );
$query->execute();

my $table = '<table align="center">';
my @titles = ( 'id', 'date', 'type', 'title', 'storage', 'value' );
my $head = '';
foreach my $title ( @titles ) {
    $head .= "<th>$title</th>";
}
$table .= "<tr>$head</tr>";
while ( my $row = $query->fetchrow_hashref() ) {
    my $table_row = '<tr>';
    foreach my $title ( @titles ) {
        my $color = ( $title eq 'value' ? $row->{value} < 0 ? $color_negative : $color_positive : '' );
        $table_row .= "<td$color>$row->{$title}</td>"; 
    }
    $table_row .= '</tr>';
    $table .= $table_row;
}

$table .= '</table>';

my $sample = qq|
<!DOCTYPE html>
<html>
    <head>
        <title>Balance</title>
        <style type="text/css">
            tr.border_top td {
                border-top:1pt solid black;
            }
        </style>
    </head>
    <body>
        <h2 align="center">All costs</h2>
        <div><font size="1">$table</font></div>
    </body>
</html>
|;

print "Content-Type: text/html\n";
print $sample;

1;

