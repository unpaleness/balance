#!/usr/bin/perl

use strict;
use warnings;

use SCS::DataBase;

my $selected = $ARGV[0] || 'daily';

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
my $query = $base->prepare( "SELECT DISTINCT storage FROM records WHERE owner = 'Egor' ORDER BY 1" );
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
    SELECT $period->{$selected}->{sql} AS period,
    r.type, r.title, r.storage, r.value
    FROM records AS r
    WHERE owner = 'Egor'
    ORDER BY 1
| );
$query->execute();
my $table = '<table align="center">';
my @titles = ( 'period', 'type', 'title', @storages, 'diff', 'total' );
my $data = {};
while ( my $row = $query->fetchrow_hashref() ) {
    my $period  = $row->{period};
    my $type    = $row->{type};
    my $title   = $row->{title};
    my $storage = $row->{storage};
    my $value   = $row->{value};
    if (!defined $data->{$period}) {
        $data->{$period} = {}; 
        $data->{$period}->{n} = 0;
        $data->{$period}->{total} = 0;
    }
    $data->{$period}->{$type} = {} if !defined $data->{$period}->{$type};
    if (!defined $data->{$period}->{$type}->{$title}) {
        $data->{$period}->{$type}->{$title} = {};
        ++$data->{$period}->{n};
    }
    $data->{$period}->{$type}->{$title}->{total} = 0 if !defined $data->{$period}->{$type}->{$title}->{total};
    $data->{$period}->{$type}->{$title}->{$storage} = 0 if !defined $data->{$period}->{$type}->{$title}->{$storage};
    $data->{$period}->{$type}->{$title}->{$storage} += $value;
    $totals->{$storage} += $value;
    $totals->{total} += $value;
    $data->{$period}->{$type}->{$title}->{total} += $value;
    $data->{$period}->{total} += $value;
}

my $head = '';
foreach my $title ( @titles ) {
    $head .= "<th>$title</th>";
}
$table .= "<tr>$head</tr>";

my $table_row = '<td colspan="3" align="center"><b>Total now</b></td>';
foreach my $storage ( @storages ) {
    my $val = $totals->{$storage};
    my $color = $val > 0 ? $color_positive : $val < 0 ? $color_negative : '';
    $table_row .= '<td' . $color . '><b>' . sprintf("%.2f", $val) . '</b></td>';
}
my $val = $totals->{total};
my $color = $val > 0 ? $color_positive : $val < 0 ? $color_negative : '';
$table_row .= '<td></td><td' . $color . '><b>' . sprintf("%.2f", $val) . '</b></td';
$table .= "<tr>$table_row</tr>";

foreach my $period ( sort keys %{ $data } ) {
    my $n = 0;
    my $n_records = $data->{$period}->{n};
    foreach my $type ( sort keys %{ $data->{$period} } ) {
        next if $type eq 'n';
        next if $type eq 'total';
        foreach my $title ( sort keys %{ $data->{$period}->{$type} } ) {
            my $table_row = ( $n == 0 ? "<td rowspan=\"$n_records\">$period</td>" : '' ) . "<td>$type</td><td>$title</td>";
            my $record = $data->{$period}->{$type}->{$title};
            my $diff = 0;
            foreach my $storage ( @storages ) {
                if ( defined $record->{$storage} ) {
                    my $val = $record->{$storage};
                    my $color = $val > 0 ? $color_positive : $val < 0 ? $color_negative : '';
                    $table_row .= '<td' . $color . '>' . sprintf("%.2f", $val) . '</td>';
                    $diff += $record->{$storage};
                    $diffs->{$storage} += $record->{$storage};
                } else {
                    $table_row .= '<td></td>';
                }
            }
            $diffs->{total} += $record->{total};
            my $color = $diff > 0 ? $color_positive : $diff < 0 ? $color_negative : '';
            $table_row .= '<td' . $color . '><b>' . ( $diff ? sprintf("%.2f", $diff) : '' ) . '</b></td>';
            if ( $n == 0 ) {
                my $val = $data->{$period}->{total};
                $color = $val > 0 ? $color_positive : $val < 0 ? $color_negative : '';
                $table_row .= '<td rowspan="' . $n_records . '" ' . $color . '><b>' . sprintf("%.2f", $val) . '</b></td>';
            }
            $table .= '<tr' . ( $n == 0 ? ' class="border_top"' : '' ) . ">$table_row</tr>";
            ++$n;
        }
    }
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

