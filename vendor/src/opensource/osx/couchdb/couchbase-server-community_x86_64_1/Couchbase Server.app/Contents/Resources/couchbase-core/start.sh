#!/bin/sh

COUCHBASE_TOP=`pwd`
export COUCHBASE_TOP

DYLD_LIBRARY_PATH="$COUCHBASE_TOP:$COUCHBASE_TOP/lib"
export DYLD_LIBRARY_PATH

echo DYLD_LIBRARY_PATH is "$DYLD_LIBRARY_PATH"

PATH="$COUCHBASE_TOP:$COUCHBASE_TOP/bin":/bin:/usr/bin
export PATH

epmd -daemon

datadir="$HOME/Library/Application Support/Couchbase"

mkdir -p "$datadir/var/lib/couchbase/logs"
cd "$datadir"

ERL_LIBS="$COUCHBASE_TOP/lib/couchdb/erlang/lib:$COUCHBASE_TOP/lib/ns_server/erlang/lib"
export ERL_LIBS

DONT_START_COUCH=1
export DONT_START_COUCH

mkdir -p "$datadir/etc/couchbase"

sed -e "s|@DATA_PREFIX@|$datadir|g" -e "s|@BIN_PREFIX@|$COUCHBASE_TOP|g" \
    "$COUCHBASE_TOP/etc/couchbase/static_config.in" > "$datadir/etc/couchbase/static_config"

exec erl \
    +A 16 \
    -setcookie nocookie \
    -kernel inet_dist_listen_min 21100 inet_dist_listen_max 21299 \
    $* \
    -run ns_bootstrap -- \
    -ns_server config_path "\"$datadir/etc/couchbase/static_config\"" \
    -ns_server pidfile "\"$datadir/couchbase-server.pid\"" \
    -ns_server dont_suppress_stderr_logger true
