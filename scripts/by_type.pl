#!/usr/bin/perl

use strict;
use warnings;

use SCS::DataBase;

my $selected = $ARGV[0] || 'monthly';

my $color_positive = ' bgcolor="#88ff88"';
my $color_negative = ' bgcolor="#ff8888"';
my $color_zero = ' bgcolor="#ffff88"';
my $period = {
    annually => {
        sql   => "DATE_FORMAT(r.date, '%Y')",
        label => 'Annually',
    },
    monthly => {
        sql   => "DATE_FORMAT(r.date, '%Y-%m')",
        label => 'Monthly',
    },
    weekly => {
        sql   => "CONCAT_WS(' - ', r.date - INTERVAL WEEKDAY(r.date) DAY, r.date + INTERVAL 6 - WEEKDAY(r.date) DAY)",
        label => 'Weekly',
    },
    daily => {
        sql   => 'r.date',
        label => 'Daily',
    },
};

my $base = SCS::DataBase->connect();
my $query = $base->prepare( 'SELECT DISTINCT type FROM records ORDER BY 1' );
$query->execute();
my @types = ();
my $totals = {};
while ( my $row = $query->fetchrow_hashref() ) {
    push @types, $row->{type};
    $totals->{$row->{type}} = 0;
}

$query = $base->prepare( qq|
    SELECT $period->{$selected}->{sql} AS period,
    r.type, SUM(r.value) AS value
    FROM records AS r
    GROUP BY 1,2
    ORDER BY 1,2
| );
$query->execute();
my $table = '<table align="center">';
my @titles = ( 'Period', @types, 'Diff', 'Total' );
my $data = {};
while ( my $row = $query->fetchrow_hashref() ) {
    my $period  = $row->{period};
    my $type    = $row->{type};
    my $value   = $row->{value};
    if (!defined $data->{$period}) {
        $data->{$period} = {}; 
        $data->{$period}->{total} = 0;
    }
    $data->{$period}->{$type} = $value;
    $data->{$period}->{total} += $value;
    $totals->{$type} += $value;
    $totals->{total} += $value;
}

my $head = '';
foreach my $title ( @titles ) {
    $head .= "<th>$title</th>";
}
$table .= "<tr>$head</tr>";

my $table_row = '<td align="center"><b>Total</b></td>';
foreach my $type ( @types ) {
    my $val = $totals->{$type};
    my $color = $val > 0 ? $color_positive : $val < 0 ? $color_negative : '';
    $table_row .= '<td' . $color . '><b>' . sprintf("%.2f", $val) . '</b></td>';
}
my $val = $totals->{total};
my $color = $val > 0 ? $color_positive : $val < 0 ? $color_negative : '';
$table_row .= '<td></td><td' . $color . '><b>' . sprintf("%.2f", $val) . '</b></td';
$table .= "<tr>$table_row</tr>";

my $current_balance = 0;

foreach my $period ( sort keys %{ $data } ) {
    my $table_row = "<td>$period</td>";
    foreach my $type ( @types ) {
        next if $type eq 'total';
        my $val = $data->{$period}->{$type};
        if ( defined $val && $val != 0 ) {
            my $color = $val > 0 ? $color_positive : $val < 0 ? $color_negative : '';
            $table_row .= '<td' . $color . '>' . sprintf("%.2f", $val) . '</td>';
        } else {
            $table_row .= '<td></td>';
        }
    }
    my $val = $data->{$period}->{total};
    my $color = $val > 0 ? $color_positive : $val < 0 ? $color_negative : '';
    $table_row .= '<td' . $color . '><b>' . ( $val ? sprintf("%.2f", $val) : '' ) . '</b></td>';
    $current_balance += $data->{$period}->{total};
    $color = $current_balance > 0 ? $color_positive : $current_balance < 0 ? $color_negative : '';
    $table_row .= '<td' . $color . '><b>' . ( $current_balance ? sprintf("%.2f", $current_balance) : '' ) . '</b></td>';
    $table .= "<tr>$table_row</tr>";
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
        <h2 align="center">$period->{$selected}->{label} costs</h2>
        <div><font size="1">$table</font></div>
    </body>
</html>
|;

print "Content-Type: text/html\n";
print $sample;

1;

