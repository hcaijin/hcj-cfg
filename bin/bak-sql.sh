#!/bin/bash

# SETTING
TOEMAIL="hcjonline@gmail.com";
COMMENT='blog database backup'
DIR='hcaijin'
# END SETTING

TMP='/tmp/diabak/'${DIR}
ATTTMP='/tmp/diabakatt/'${DIR}

rm -rf $TMP
mkdir -p $TMP
cd $TMP

# Put files what you want to backup to $TMP
# 1.备份单个数据库
# mysqldump --user=user --password=password --lock-all-tables dbname > backup.sql
# 2.备份多个数据库
# mysqldump --user=user --password=password --lock-all-tables --databases dbname1 dbname2 > backup.sql
# 3.备份所有数据库
# mysqldump --user=user --password=password --lock-all-tables --all-databases > backup.sql

/usr/local/mysql/bin/mysqldump --user=root --password=H_caijin --lock-all-tables --databases pinphp_db wp_db > backup.sql

cp backup.sql /home/hcaijin/backup-sql/bak_$(date +"%Y%m%d").sql

# Don't change anything below
YYYYMMDD=`date +%Y%m%d`
SUBJECT='DiaBak_of_'${DIR}'_'${YYYYMMDD};

rm -rf $ATTTMP
mkdir -p $ATTTMP
cd $ATTTMP

tar zcPf backup.tar.gz $TMP
rm -rf $TMP
split -b 20m -a 3 -d backup.tar.gz ${SUBJECT}.part
rm -f backup.tar.gz

for file in *
do
    echo $COMMENT | mutt $TOEMAIL -s $SUBJECT -a $file 
    sleep 30s
done

rm -rf $ATTTMP
rm -f /home/hcaijin/backup-sql/bak_$(date -d -7day +"%Y%m%d").sql
