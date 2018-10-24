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

unless ( defined $period->{$selected} ) {
    my $sample = qq|
    <!DOCTYPE html>
    <html>
        <head><title>Bad parameter</title></head>
        <body>
            <h2 align="center">Bad command line agrument</h2>
        </body>
    </html>
    |;
    print "Content-Type: text/html\n";
    print $sample;
    exit 0;
}

my $base = SCS::DataBase->connect();
my $query = $base->prepare( qq|
    SELECT
        $period->{$selected}->{sql} AS period,
        r.title,
        SUM(r.value) AS diff
    FROM records AS r
    GROUP BY 1, 2
    ORDER BY 1, 2
| );
$query->execute();
my $table = '<table align="center">';
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
        my $color = $diff !~ /[0-9,.+-]/ ? '' : $diff > 0 ? $color_positive : $diff < 0 ? $color_negative : '';
        $table_row .= "<td$color>$diff</td>";
    }
    $sum = sprintf("%.2f", $sum);
    my $color = $sum !~ /[0-9,.+-]/ ? '' : $sum > 0 ? $color_positive : $sum < 0 ? $color_negative : '';
    $table_row .= "<td$color><b>$sum</b></td>";
    $table .= "<tr>$table_row</tr>";
}
my $table_row = '<td><b>Total</b></td>';
my $sum = 0;
foreach my $title ( sort keys %{ $titles } ) {
    my $diff = '';
    $diff = sprintf("%.2f", $total->{ $title }) if $total->{ $title };
    my $color = $diff !~ /[0-9,.+-]/ ? '' : $diff > 0 ? $color_positive : $diff < 0 ? $color_negative : '';
    $table_row .= "<td$color><b>$diff</b></td>";
    $sum += $diff;
}
$sum = sprintf("%.2f", $sum);
my $color = $sum !~ /[0-9,.+-]/ ? '' : $sum > 0 ? $color_positive : $sum < 0 ? $color_negative : '';
$table_row .= "<td$color><b>$sum</b></td>";
$table .= "<tr>$table_row</tr>";
$table .= '</table>';

my $sample = qq|
<!DOCTYPE html>
<html>
    <head><title>Balance</title></head>
    <body>
        <h2 align="center">$period->{$selected}->{label} detailed balance</h2>
        <div><font size="1">$table</font></div>
    </body>
</html>
|;

print "Content-Type: text/html\n";
print $sample;

1;

