#!/bin/bash

hostname=`hostname -f`
# This is an example script that creates a single shard vttablet deployment.

set -e

# 这种写法是如果设置了环境变量就用环境变量，如果没有则默认值为'test'
# cell=${cell:-'test'}


cell=${cell:-'test'}
keyspace=${keyspace:-'test_keyspace'}
shard=${shard:-0}
uid=${uid:-100}
tablet_type=${tablet_type:-'replica'}
port=${port:-15100}
grpc_port=${grpc_port:-16100}
mysql_port=${mysql_port:-33100}
etcd_global_addrs=${etcd_global_addrs:-'http://etcd-alias:2379'}



dbconfig_flags="\
    -db-config-app-uname vt_app \
    -db-config-app-dbname vt_$keyspace \
    -db-config-app-charset utf8 \
    -db-config-dba-uname vt_dba \
    -db-config-dba-charset utf8 \
    -db-config-repl-uname vt_repl \
    -db-config-repl-dbname vt_$keyspace \
    -db-config-repl-charset utf8 \
    -db-config-filtered-uname vt_filtered \
    -db-config-filtered-dbname vt_$keyspace \
    -db-config-filtered-charset utf8"
init_db_sql_file="$VTROOT/config/init_db.sql"

case "$MYSQL_FLAVOR" in
  "MySQL56")
    export EXTRA_MY_CNF=$VTROOT/config/mycnf/master_mysql56.cnf
    ;;
  "MariaDB")
    export EXTRA_MY_CNF=$VTROOT/config/mycnf/master_mariadb.cnf
    ;;
  *)
    echo "if you do not set MYSQL_FLAVOR,  MySQL56 is used default"
    export EXTRA_MY_CNF=$VTROOT/config/mycnf/master_mysql56.cnf
    ;;
esac


# Look for memcached.
memcached_path=`which memcached`
if [ -z "$memcached_path" ]; then
  echo "Can't find memcached. Please make sure it is available in PATH."
  exit 1
fi

# Start 3 vttablets by default.
# Pass a list of UID indices on the command line to override.
# uids=${@:-'0 1 2'}

printf -v alias '%s-%010d' $cell $uid
printf -v tablet_dir 'vt_%010d' $uid

mkdir -p $VTDATAROOT/backups
mkdir -p $VTDATAROOT/tmp

echo "Starting MySQL for tablet $alias..."
action="init -init_db_sql_file $init_db_sql_file"
if [ -d $VTDATAROOT/$tablet_dir ]; then
    echo "Resuming from existing vttablet dir:"
    echo "    $VTDATAROOT/$tablet_dir"
    action='start'
fi
$VTROOT/bin/mysqlctl \
    -log_dir $VTDATAROOT/tmp \
    -tablet_uid $uid $dbconfig_flags \
    -mysql_port $mysql_port \
    $action

echo "Starting vttablet for $alias..."
echo "Access tablet $alias at http://$hostname:$port/debug/status"
$VTROOT/bin/vttablet \
    -log_dir $VTDATAROOT/tmp \
    -tablet-path $alias \
    -tablet_hostname `hostname -i` \
    -init_keyspace $keyspace \
    -init_shard $shard \
    -target_tablet_type $tablet_type \
    -health_check_interval 5s \
    -enable-rowcache \
    -rowcache-bin $memcached_path \
    -rowcache-socket $VTDATAROOT/$tablet_dir/memcache.sock \
    -backup_storage_implementation file \
    -file_backup_storage_root $VTDATAROOT/backups \
    -restore_from_backup \
    -port $port \
    -grpc_port $grpc_port \
    -binlog_player_protocol grpc \
    -service_map 'grpc-queryservice,grpc-tabletmanager,grpc-updatestream' \
    -pid_file $VTDATAROOT/$tablet_dir/vttablet.pid \
    -topo_implementation etcd \
    -etcd_global_addrs $etcd_global_addrs \
    $dbconfig_flags \
    > $VTDATAROOT/$tablet_dir/vttablet.out 2>&1

# add this line keep docker running
tail -f $VTDATAROOT/tmp/*  $VTDATAROOT/$tablet_dir/vttablet.out