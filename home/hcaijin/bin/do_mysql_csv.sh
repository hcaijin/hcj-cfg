#!/bin/sh

. /home/hcaijin/bin/mysql_csv.sh

# MYSQL_CSV_FORMAT="fields terminated by ',' optionally enclosed by '\"' escaped by '\"' lines terminated by '\r\n'"
echo "MYSQL_CSV_FORMAT=$MYSQL_CSV_FORMAT"

rm /tmp/test.csv

mysql -p --default-character-set=gbk -t --verbose test <<EOF

use test;

create table if not exists test_info (
    id  integer not null,
    content varchar(64) not null,
    primary key (id)
);

delete from test_info;

insert into test_info values (2010, 'hello, line
suped
seped
"
end'
);

select * from test_info;

-- select * from test_info into outfile '/tmp/test.csv' fields terminated by ',' optionally enclosed by '"' escaped by '"' lines terminated by '\r\n';
select * from test_info into outfile '/tmp/test.csv' $MYSQL_CSV_FORMAT;

delete from test_info;

-- load data infile '/tmp/test.csv' into table test_info fields terminated by ','  optionally enclosed by '"' escaped by '"' lines terminated by '\r\n';
load data infile '/tmp/test.csv' into table test_info $MYSQL_CSV_FORMAT;

select * from test_info;


EOF

echo "===== content in /tmp/test.csv ====="
cat /tmp/test.csv
