#!/bin/bash
set -e

declare needs=( end_tag )
declare wants=( src_repo commit help dry_run )
declare -A tests=( [src_repo]=1 )

progdir="$(dirname $(realpath $0) )"
source "${progdir}/common.sh"

pushd ${SRC_REPO}/contrib/ast-db-manage &>/dev/null

# The sample config files are all set up for MySql
# so we'll do those first.
$ECHO_CMD mkdir -p ../realtime/mysql || : 
for schema in config voicemail queue_log cdr ; do
	if $DRY_RUN ; then
		echo "alembic -c ./$schema.ini.sample --sql upgrade head > ../realtime/mysql/mysql_${schema}.sql"
	else
		alembic -c ./$schema.ini.sample --sql upgrade head > ../realtime/mysql/mysql_${schema}.sql
	fi
done

trap "rm -f /tmp/*.sample.ini &>/dev/null " EXIT

# We need to generate a config file for postgresql.
$ECHO_CMD mkdir -p ../realtime/postgresql || : 
for schema in config voicemail queue_log cdr ; do
	if $DRY_RUN ; then
		echo "alembic -c ./$schema.ini.sample --sql upgrade head > ../realtime/postgresql/postgresql_${schema}.sql"
	else
		sed -r -e "s/^#(sqlalchemy.url\s*=\s*postgresql)/\1/g" -e "s/^(sqlalchemy.url\s*=\s*mysql)/#\1/g" ./${schema}.ini.sample > /tmp/${schema}.ini.sample	
		alembic -c /tmp/$schema.ini.sample --sql upgrade head > ../realtime/postgresql/postgresql_${schema}.sql
	fi
done

popd &>/dev/null

if ${COMMIT} ; then
	$ECHO_CMD git -C ${SRC_REPO} add contrib/realtime
	$ECHO_CMD git -C ${SRC_REPO} commit -a -m "Alembic SQL scripts for ${END_TAG}"
fi

