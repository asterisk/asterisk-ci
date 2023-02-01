#!/bin/bash
set -e

declare needs=( start_tag end_tag )
declare wants=( src_repo dst_dir )
declare tests=( start_tag src_repo dst_dir )

# Since creating the changelog doesn't make any
# changes, we're not bothering with dry-run.

progdir="$(dirname $(realpath $0) )"
source "${progdir}/common.sh"

mkdir -p /tmp/asterisk
TMPFILE1=/tmp/asterisk/ChangeLog-${END_TAG}.tmp1.txt
TMPFILE2=/tmp/asterisk/ChangeLog-${END_TAG}.tmp2.txt
trap "rm -f $TMPFILE1 $TMPFILE2" EXIT


# This gets a somewhat machine readable list of commits
# that don't include any commit with a subject that starts
# ChangeLog.  This way we don't include the changelog from
# the previous release.
debug "Getting commit list for ${START_TAG}..HEAD"
git -C "${SRC_REPO}" --no-pager log \
	--format='format:@#@#@#@%nSubject: %s%nAuthor: %an%nDate:   %as%n%n%b%n#@#@#@#' \
	--grep "^Add ChangeLog" --invert-grep ${START_TAG}..HEAD >"${TMPFILE2}"

if [ ! -s "${TMPFILE2}" ] ; then
	bail "There are no commits in the range ${START_TAG}..HEAD.
	Do you need to cherry pick?"
fi



cat <<-EOF >"${TMPFILE1}"
Change Log for Release ${END_TAG}
=================================

Summary:
--------

EOF

# For the summary, we want only the commit
# subject plus any Upgrade or User notes.
debug "Creating summary"
sed -r -e '/^$/d' "${TMPFILE2}" |\
	sed -n -r -e "s/^Subject:\s+(.+)/- \1/p" \
	-e '/^(Upgrade|User)Note:/,/((Upgrade|User)Note:)||(^[-])/!d ; s/(.)/    \1/p' \
		>>"${TMPFILE1}"

cat <<-EOF >>"${TMPFILE1}"

Closed Issues:
-------

EOF

# Anything that matches the regex is a GitHub issue
# number.  We're going to list the issues here but also
# save them to 'issues_to_close.txt' so we can close them
# later without having to pull them all again.
debug "Getting issues list"
issuelist=( $(sed -n -r -e "s/^\s*Fixes:\s*#([0-9]+)/\1/gp" "${TMPFILE2}") )
rm "${DST_DIR}/issues_to_close.txt" &>/dev/null || :

if [ ${#issuelist[*]} -gt 0 ] ; then
	echo "${issuelist[*]}" > "${DST_DIR}/issues_to_close.txt"
	debug "Getting ${#issuelist[*]} issue titles from GitHub"
	# The issues in issuelist are separated by newlines
	# but we want them seaprated by commas for the jq query
	# so we set IFS=, to make ${issuelist[*]} print them
	# that way. 
	IFS=,
	# We want the issue number and the title formatted like:
	#   - #2: Issue Title
	# which GitHub can do for us using a jq format string.
	gh --repo=asterisk/$(basename ${SRC_REPO}) issue list \
		--json number,title \
		--jq "[ .[] | select(.number|IN(${issuelist[*]}))] | sort_by(.number) | .[] | \"  - #\" + ( .number | tostring) + \": \" + .title" \
		>>"${TMPFILE1}"
	# Reset IFS back to its normal special value
	unset IFS
else
	touch "${DST_DIR}/issues_to_close.txt"
	debug "No issues"
	echo "None" >> "${TMPFILE1}"
fi
cat <<-EOF >>"${TMPFILE1}"

Commits By Author:
------------------

EOF

# git shortlog can give us a list of commit authors
# and the number of commits in the tag range.
debug "Getting shortlog for authors"
git -C "${SRC_REPO}" shortlog --grep "^Add ChangeLog" --invert-grep \
	--group="format:- %an" --format="- %s" ${START_TAG}..HEAD |\
	sed -r -e "s/^\s+/    /g" >>"${TMPFILE1}"

cat <<-EOF >>"${TMPFILE1}"

Detail:
------------------

EOF
debug "Adding the details"
# Clean up the tags we added to make parsing easier.
sed -r -e "s/^(.)/  \1/g" \
	-e '/@#@#@#@/,/Subject:/p ; s/^  Subject:\s+([^ ].+)/- \1/g' \
	"${TMPFILE2}" |\
	 sed -r -e '/#@#@#@#|@#@#@#@|Subject:/d' >> "${TMPFILE1}"

cp "${TMPFILE1}" "${DST_DIR}/ChangeLog-${END_TAG}.txt"
debug "Done"
