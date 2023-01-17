#!/bin/bash
set -e

declare needs=( start_tag end_tag )
declare wants=( src_repo dst_dir alembic changelog commit tag push \
				tarball patchfile close_issues sign full_monty help dry_run )
declare -A tests=( [start_tag]=1 [end_tag]=1 [src_repo]=1 [dst_dir]=1 )

progdir="$(dirname $(realpath $0) )"
source "${progdir}/common.sh"

if ${CHANGELOG} ; then
	echo "${END_TAG}" > ${DST_DIR}/.version
	$ECHO_CMD $progdir/create_changelog.sh --start-tag=${START_TAG} --end-tag=${END_TAG} \
		--src-repo=${SRC_REPO} --dst-dir=${DST_DIR}

	if [ ! -d ${SRC_REPO}/ChangeLogs ] ; then
		$ECHO_CMD mkdir -p ${SRC_REPO}/ChangeLogs
	fi

	if ${COMMIT} ; then
		$ECHO_CMD cp ${DST_DIR}/.version ${SRC_REPO}/.version
		$ECHO_CMD cp ${DST_DIR}/ChangeLog-${END_TAG}.txt ${SRC_REPO}/ChangeLogs/
q		$ECHO_CMD git -C ${SRC_REPO} add .version ChangeLogs/ChangeLog-${END_TAG}.txt
		$ECHO_CMD git -C ${SRC_REPO} commit -a -m "Add ChangeLog for release ${END_TAG}"
	fi
fi

if ${TAG} ; then
	$ECHO_CMD git -C ${SRC_REPO} tag -a ${END_TAG} -m ${END_TAG}
	if ${PUSH} ; then
		$ECHO_CMD git -C ${SRC_REPO} push
		$ECHO_CMD git -C ${SRC_REPO} push origin ${END_TAG}:${END_TAG}
	fi
fi

if ${TARBALL} ; then
	$ECHO_CMD $progdir/create_tarball.sh --start-tag=${START_TAG} --end-tag=${END_TAG} \
		--src-repo=${SRC_REPO} --dst-dir=${DST_DIR} ${SIGN:+--sign}
fi

if ${PATCHFILE} ; then
	$ECHO_CMD $progdir/create_patchfile.sh --start-tag=${START_TAG} --end-tag=${END_TAG} \
	--src-repo=${SRC_REPO} --dst-dir=${DST_DIR} ${SIGN:+--sign}
fi

if ${CLOSE_ISSUES} ; then
	$ECHO_CMD $progdir/close_issues.sh --start-tag=${START_TAG} --end-tag=${END_TAG} \
		--src-repo=${SRC_REPO} --dst-dir=${DST_DIR}
fi

