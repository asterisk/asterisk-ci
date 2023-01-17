#!/bin/bash
set -e

declare needs=( end_tag )
declare wants=( src_repo dst_dir help dry_run )
declare -A tests=( [end_tag]=1 src_repo]=1 [dst_dir]=1 )

progdir="$(dirname $(realpath $0) )"
source "${progdir}/common.sh"

if [ ! -f "${DST_DIR}/issues_to_close.txt" ] ; then
	bail "File '${DST_DIR}/issues_to_close.txt' doesn't exist."
fi

issuelist=$( cat "${DST_DIR}/issues_to_close.txt" )

# We need to create a label like 'Release/20.1.0' if
# one doesn't already exist.
gh --repo asterisk/$(basename ${SRC_REPO}) \
	label list --json name --search "Release/${END_TAG}" |\
	grep -q "Release/${END_TAG}" || {
		$ECHO_CMD gh --repo asterisk/$(basename ${SRC_REPO}) \
		label create "Release/${END_TAG}" --color "#16E26B" \
		--description "Fixed in release ${END_TAG}"
	} 

# GitHub makes this easy..  Add the label then close the issue.
for issue in $issuelist ; do
	$ECHO_CMD gh --repo asterisk/$(basename ${SRC_REPO}) issue edit $issue --add-label ${END_TAG}
	$ECHO_CMD gh --repo asterisk/$(basename ${SRC_REPO}) issue close $issue --reason "completed" --comment "Released in version ${END_TAG}"
done
