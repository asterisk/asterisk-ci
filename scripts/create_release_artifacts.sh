#!/bin/bash
set -e

declare needs=( end_tag )
declare wants=( src_repo dst_dir security norc alembic
				changelog commit tag push tarball patchfile
				close_issues sign full_monty dry_run )
declare tests=( src_repo dst_dir )

progdir="$(dirname $(realpath $0) )"
source "${progdir}/common.sh"

declare -A end_tag
tag_parser ${END_TAG} end_tag || bail "Unable to parse end tag '${END_TAG}'"
${DEBUG} && declare -p end_tag

if [ -z "${START_TAG}" ] ; then
	START_TAG=$($progdir/get_start_tag.sh \
		--end-tag=${END_TAG} --src-repo="${SRC_REPO}" \
		$(booloption security) $(booloption norc) $(booloption debug) )
fi
if [ -z "${START_TAG}" ] ; then
	bail "can't determine a start tag"
fi		

if ${CHERRY_PICK} ; then
	commitlist=$(mktemp)
	git -C "${SRC_REPO}" cherry ${END_TAG} ${end_tag[source_branch]} |\
		sed -n -r -e "s/^[+]\s?(.*)/\1/gp" > ${commitlist}
	commitcount=$(wc -l ${commitlist})
	debug "Cherry picking $commitcount commits from ${end_tag[source_branch]} to ${end_tag[branch]}"
	${ECHO_CMD} git -C "${SRC_REPO}" checkout ${end_tag[source_branch]}
	${ECHO_CMD} git -C "${SRC_REPO}" cherry-pick -ff -x $(cat ${commitlist})
	rm ${commitlist} &>/dev/null || : 
	debug "Done"
fi

if ${ALEMBIC} ; then
	debug "Creating Alembic scripts for ${END_TAG}"
	$ECHO_CMD $progdir/create_alembic_scripts.sh --start-tag=${START_TAG} --end-tag=${END_TAG} \
		--src-repo="${SRC_REPO}" --dst-dir="${DST_DIR}" $(${COMMIT} && echo "--commit")
fi

if ${CHANGELOG} ; then
	debug "Creating ChangeLog for ${START_TAG} -> ${END_TAG}"
	echo "${END_TAG}" > ${DST_DIR}/.version
	$ECHO_CMD $progdir/create_changelog.sh --start-tag=${START_TAG} --end-tag=${END_TAG} \
		--src-repo="${SRC_REPO}" --dst-dir="${DST_DIR}"

	if [ ! -d ${SRC_REPO}/ChangeLogs ] ; then
		$ECHO_CMD mkdir -p ${SRC_REPO}/ChangeLogs
	fi

	if ${COMMIT} ; then
		$ECHO_CMD cp ${DST_DIR}/.version ${SRC_REPO}/.version
		$ECHO_CMD cp ${DST_DIR}/ChangeLog-${END_TAG}.txt ${SRC_REPO}/ChangeLogs/
		$ECHO_CMD git -C "${SRC_REPO}" add .version ChangeLogs/ChangeLog-${END_TAG}.txt
		$ECHO_CMD git -C "${SRC_REPO}" commit -a -m "Add ChangeLog for release ${END_TAG}"
	fi
fi

if ${TAG} ; then
	${COMMIT} || bail "There was no commit so there's nothing to tag"
	debug "Creating tag for ${END_TAG}"
	$ECHO_CMD git -C "${SRC_REPO}" tag -a ${END_TAG} -m ${END_TAG}
	if ${PUSH} ; then
		$ECHO_CMD git -C "${SRC_REPO}" push
		$ECHO_CMD git -C "${SRC_REPO}" push origin ${END_TAG}:${END_TAG}
	fi
fi

if ${TARBALL} ; then
	debug "Creating tarball for ${END_TAG}"
	$ECHO_CMD $progdir/create_tarball.sh --start-tag=${START_TAG} --end-tag=${END_TAG} \
		--src-repo="${SRC_REPO}" --dst-dir="${DST_DIR}" $(${SIGN} && echo "--sign")
fi

if ${PATCHFILE} ; then
	debug "Creating patchfile for ${END_TAG}"
	$ECHO_CMD $progdir/create_patchfile.sh --start-tag=${START_TAG} --end-tag=${END_TAG} \
	--src-repo="${SRC_REPO}" --dst-dir="${DST_DIR}" $(${SIGN} && echo "--sign")
fi

if ${LABEL_ISSUES} ; then
	debug "Labelling close issues for ${END_TAG}"
	$ECHO_CMD $progdir/label_issues.sh --start-tag=${START_TAG} --end-tag=${END_TAG} \
		--src-repo="${SRC_REPO}" --dst-dir="${DST_DIR}"
fi

if ${PUSH_LIVE} ; then
	debug "Pushing Asterisk Release ${END_TAG} live"
	$ECHO_CMD gh release create ${END_TAG} --notes-file ${DST_DIR}/ChangeLog-${END_TAG}.txt \
		--target Releases/20 -t "Asterisk Release ${END_TAG}" \
		${DST_DIR}/asterisk-${END_TAG}.*	
fi



