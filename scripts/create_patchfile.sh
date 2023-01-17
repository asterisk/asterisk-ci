#!/bin/bash

declare needs=( start_tag end_tag )
declare wants=( src_repo dst_dir sign help dry_run )
declare -A tests=( [start_tag]=1 [end_tag]=1 src_repo]=1 [dst_dir]=1 )

progdir="$(dirname $(realpath $0) )"
source "${progdir}/common.sh"

patchfile="asterisk-${END_TAG}.patch"
$ECHO_CMD git --no-pager -C "${SRC_REPO}" diff --no-color --output="${DST_DIR}/${patchfile}" ${START_TAG}..${END_TAG} || bail "Unable to create patchfile"
$ECHO_CMD tar -C "${DST_DIR}" -czf "${DST_DIR}/${patchfile}.tar.gz" "${patchfile}" || bail "Unable to create tarfile"
$ECHO_CMD rm "${DST_DIR}/${patchfile}" 2>/dev/null
 
pushd ${DST_DIR} &>/dev/null
for alg in md5 sha1 sha256 ; do
	$ECHO_CMD ${alg}sum ${patchfile}.tar.gz > ${patchfile}.${alg}
done 
# The gpg key is installed automatically by the GitHub action.
# If running standalone, your default gpg key will be used.
$SIGN && $ECHO_CMD gpg --detach-sign --armor ${patchfile}.tar.gz

popd &>/dev/null

