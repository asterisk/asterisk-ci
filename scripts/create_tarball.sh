#!/bin/bash

declare needs=( end_tag )
declare wants=( src_repo dst_dir sign dry_run )
declare tests=( end_tag src_repo dst_dir )

progdir="$(dirname $(realpath $0) )"
source "${progdir}/common.sh"

# Before we create the tarball, we need to retrieve
# a few basic sounds files.
$ECHO_CMD make -C "${SRC_REPO}/sounds" \
	MENUSELECT_CORE_SOUNDS=CORE-SOUNDS-EN-GSM \
	MENUSELECT_MOH=MOH-OPSOUND-WAV \
	WGET=wget \
	DOWNLOAD=wget all || bail "Unable to download sounds tarballs"

# Git creates the tarball for us but we need to tell it
# to include the unversioned sounds files just downloaded.
$ECHO_CMD git -C "${SRC_REPO}" archive --format=tar.gz \
	-o "${DST_DIR}/asterisk-${END_TAG}.tar.gz" \
	--prefix="asterisk-${END_TAG}/sounds/" \
	$(find "${SRC_REPO}/sounds/" -name "asterisk*.tar.gz" -printf " --add-file=sounds/%P") \
	--prefix="asterisk-${END_TAG}/" "${END_TAG}" || bail "Unable to create tarball"

pushd ${DST_DIR} &>/dev/null
for alg in md5 sha1 sha256 ; do
	$ECHO_CMD ${alg}sum asterisk-${END_TAG}.tar.gz > asterisk-${END_TAG}.${alg}
done 
# The gpg key is installed automatically by the GitHub action.
# If running standalone, your default gpg key will be used.
$SIGN && $ECHO_CMD gpg --detach-sign --armor asterisk-${END_TAG}.tar.gz
popd &>/dev/null
