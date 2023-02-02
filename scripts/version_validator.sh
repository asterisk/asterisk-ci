#!/bin/bash
set -e

declare needs=( end_tag )
declare wants=( start_tag src_repo certified security )
declare tests=( src_repo )

progdir="$(dirname $(realpath $0) )"
source "${progdir}/common.sh"

declare -A end_tag
tag_parser ${END_TAG} end_tag || bail "Unable to parse end tag '${END_TAG}'"
${DEBUG} && declare -p end_tag

declare -A start_tag
if [ -n "${START_TAG}" ] ; then
	tag_parser ${START_TAG} start_tag || bail "Unable to parse start tag '${START_TAG}'"
	${DEBUG} && declare -p start_tag
fi

if [ -z "${SRC_REPO}" ] ; then
	echo "${progname}: Tags are formatted correctly."
	exit 0
fi

$progdir/get_start_tag.sh ${START_TAG:+--start-tag=${START_TAG}} \
	--end-tag=${END_TAG} --src-repo="${SRC_REPO}" \
	$(booloption SECURITY) $(booloption CERTIFIED)

exit 0