#!/bin/bash

# This is an example script that stops the mysqld and vttablet instances
# created by vttablet-up.sh

set -e

# 这种写法是如果设置了环境变量就用环境变量，如果没有则默认值为'test'
# cell=${cell:-'test'}
cell=${cell:-'test'}
uid=${uid:-100}


printf -v alias '%s-%010d' $cell $uid
printf -v tablet_dir 'vt_%010d' $uid

echo "Stopping vttablet for $alias..."
pid=`cat $VTDATAROOT/$tablet_dir/vttablet.pid`
echo "kill pid $pid of $VTDATAROOT/$tablet_dir/vttablet.pid"
kill $pid

echo "Stopping MySQL for tablet $alias..."
$VTROOT/bin/mysqlctl \
-db-config-dba-uname vt_dba \
-tablet_uid $uid \
shutdown
