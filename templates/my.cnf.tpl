[mysqld]
user        = mysql
pid-file    = /var/run/mysqld/mysqld.pid
socket      = /var/run/mysqld/mysqld.sock
port        = 3306
basedir     = /usr
datadir     = /var/lib/mysql
tmpdir      = /tmp
lc-messages-dir = /usr/share/mysql
skip-external-locking

max_allowed_packet      = 500M
thread_stack            = 1M
thread_cache_size       = 64
query_cache_limit       = 8M
query_cache_size        = 96M

default_storage_engine  = InnoDB
binlog_format           = ROW

general_log_file        = /var/log/mysql/mysql.log
general_log             = 1
log_error               = /var/log/mysql/error.log
slow_query_log_file     = /var/log/mysql/mysql-slow.log
slow_query_log          = 1
long_query_time         = 2
log_queries_not_using_indexes

server-id           = _SERVER_ID_
log_bin             = /var/log/mysql/mysql-bin.log
expire_logs_days    = 10
max_binlog_size     = 100M

innodb_flush_log_at_trx_commit  = 0
innodb_flush_method             = O_DIRECT
innodb_file_per_table           = 1
innodb_autoinc_lock_mode        = 2

bind_address = 0.0.0.0

wsrep_slave_threads     = 2
wsrep_cluster_address   = gcomm://_NODE1_HOST_,_NODE2_HOST_,_NODE3_HOST_
wsrep_provider          = /usr/lib/galera3/libgalera_smm.so
wsrep_cluster_name      = _CLUSTER_NAME_
wsrep_node_name         = _NODE_NAME_
wsrep_node_address      = _NODE_HOST_
pxc_strict_mode         = ENFORCING
wsrep_sst_method        = xtrabackup-v2
wsrep_sst_auth          = "xtrabackup:"

[mysqld_safe]
socket      = /var/run/mysqld/mysqld.sock
nice        = 0

[client]
port        = 3306
socket      = /var/run/mysqld/mysqld.sock
