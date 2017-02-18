#####################################################
# Cloud specific parameters that can change
#####################################################

# Base HBase jar that contains the import/export code
HBASE_JAR=/usr/lib/hbase/hbase-0.90.4-cdh3u3.jar

# The base directory where we store the backups on HDFS
BASE_DIR=/backups

# The directory where we store logs.
LOG_DIR=/media/Hadoop/et-log/hbase/log

# Versions 
# Note that the default versions is 3, however its possible to have more than
# 3 versions in a column family. If we need to back up more, then we can 
# change the script to handle this.
VERSION=1


# List of tables that we want to get a full table scan

FULL_LIST="`echo -e list | hbase shell | tail -n+7 | head -n-2`"

DAILY_LIST=$FULL_LIST
WEEKLY_LIST=$FULL_LIST
MONTHLY_LIST=$FULL_LIST

# Create a consistent timestamp to be used as the job run.
TIMESTAMP=$( date +%Y%m%d.%H%M)

if [[ $1 ]]; then
# Build the days in ymd format for use in setting up the days 
# Build the days in # Seconds since EPOCH
T=$(date +%y%m%d)
TODAY=$( date +%y%m%d )
YESTERDAY=$(date -d " -1 day " +%y%m%d )
LASTWEEK=$(date -d " -1 week -1 day " +%y%m%d )
LASTMONTH=$(date -d " -1 month -1 day " +%y%m%d )
STOPTIME=$TODAY

case ${1} in
DAILY)
STARTTIME=$YESTERDAY
FILE_LIST=$DAILY_LIST ;;
WEEKLY)
STARTTIME=$LASTWEEK
FILE_LIST=$WEEKLY_LIST ;;
MONTHLY)
STARTTIME=$LASTMONTH
FILE_LIST=$MONTHLY_LIST ;;
FULL)
# Set start time to some day like 01-Jan-10
STARTTIME="000101"
FILE_LIST=$FULL_LIST ;;
*) echo Fell Through untouched >>$LOG_DIR/backup_log.$TIMESTAMP ;;

esac

for i in $FILE_LIST
do
echo Backing up HBase Table: $i >>$LOG_DIR/backup_log.$TIMESTAMP 2>&1
hadoop jar $HBASE_JAR export \
$i $BASE_DIR/$i.$(date +%Y%m%d.%H%M).${1} $VERSION \
$(( $( date -d $STARTTIME +%s) * 1000 )) \
$(( $( date -d $STOPTIME +%s) * 1000 )) \
>>$LOG_DIR/backup_log.$TIMESTAMP 2>&1

done
else
# No parameter specified
for i in $FULL_LIST
do
echo Backing up HBase Table: $i >>$LOG_DIR/backup_log.$TIMESTAMP 2>&1
hadoop jar $HBASE_JAR export \
$i $BASE_DIR/$i.$(date +%Y%m%d.%H%M).FULL \
>>$LOG_DIR/backup_log.$TIMESTAMP 2>&1
done
fi
