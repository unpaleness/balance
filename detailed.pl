#!/usr/bin/perl

use strict;
use warnings;

use SCS::DataBase;

my $base = SCS::DataBase->connect();
my $query = $base->prepare( qq{
    SELECT
        DATE_FORMAT(r.date, '%Y-%m') AS "period",
        r.title,
        SUM(r.value) AS diff
    FROM records AS r
    GROUP BY 1, 2
    ORDER BY 1, 2
} );
$query->execute();
my $table = '<table>';
my $titles = undef;
my @titles = ();
my $total = {};
my $data = {};
while ( my $row = $query->fetchrow_hashref() ) {
    $data->{ $row->{period} }->{ $row->{title} } = $row->{diff};
    $titles->{ $row->{title} } = 1;
}
my $head = '<th>Period</th>';
foreach my $title ( sort keys %{ $titles } ) {
    push @titles, $title;
    $head .= "<th>$title</th>";
}
$head .= "<th>Total</th>";
$table .= "<tr>$head</tr>";
foreach my $period ( sort keys %{ $data } ) {
    my $table_row = "<td>$period</td>";
    my $sum = 0;
    foreach my $title ( @titles ) {
        if ( $data->{ $period }->{ $title } ) {
            $total->{ $title } += $data->{ $period }->{ $title };
            $sum += $data->{ $period }->{ $title };
        }
        my $diff = $data->{ $period }->{ $title } || '';
        $diff = $diff ? sprintf("%.2f", $diff) : '';
        $table_row .= "<td>$diff</td>";
    }
    $sum = sprintf("%.2f", $sum);
    $table_row .= "<td><b>$sum</b></td>";
    $table .= "<tr>$table_row</tr>";
}
my $table_row = '<td><b>Total</b></td>';
my $sum = 0;
foreach my $title ( sort keys %{ $titles } ) {
    my $diff = '';
    $diff = sprintf("%.2f", $total->{ $title }) if $total->{ $title };
    $table_row .= "<td><b>$diff</b></td>";
    $sum += $diff;
}
$sum = sprintf("%.2f", $sum);
$table_row .= "<td><b>$sum</b></td>";
$table .= "<tr>$table_row</tr>";
$table .= '</table>';

my $sample = qq{
<!DOCTYPE html>
<html>
    <head><title>Balance</title></head>
    <body>
        <h2>Detailed balance</h2>
        <div><font size="1">$table</font></div>
    </body>
</html>
};

print "Content-Type: text/html\n";
print $sample;

1;

