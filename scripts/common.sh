#!/bin/bash
set -e

# Not all the scripts use all the options
# but it'seasier to just define them all here.

declare -A options=(
				   [start_tag]="--start-tag=<tag>"
				     [end_tag]="--end-tag=<tag>"
				    [src_repo]="--src-repo=<source repository>     # defaults to current directory"
				     [dst_dir]="--dest-dir=<destination directory> # defaults to ../staging"
				     [alembic]="--alembic       # Create alembic sql scripts"
				   [changelog]="--changelog     # Create changelog"
				      [commit]="--commit        # Commit changelog/alembic scripts"
				         [tag]="--tag           # Tag the release"
				        [push]="--push          # Push commit and tag upstream"
				     [tarball]="--tarball       # Create tarball"
				   [patchfile]="--patchfile     # Create patchfile"
				[close_issues]="--close-issues  # Close related issues"
				        [sign]="--sign          # Sign the tarball and patchfile"
				  [full_monty]="--full-monty    # Do everything"
				        [help]="--help"
				     [dry_run]="--dry-run       # Don't do anything, just print commands"
)

bail() {
	echo $@ >/dev/stdout
	exit 1
}

print_help() {
	unset IFS
	echo $@ >/dev/stdout
	echo "Usage: $0 " >/dev/stdout
	for x in `seq -s' ' 0 $(( ${#needs[@]} - 1 ))` ; do
		k=${needs[$x]}
		echo -e "\t${options[$k]}" >/dev/stdout
	done
	for x in `seq -s' ' 0 $(( ${#wants[@]} - 1 ))` ; do
		k=${wants[$x]}
		echo -e "\t[ ${options[$k]} ]" >/dev/stdout
	done
	
	exit 1
}

START_TAG=
END_TAG=
SRC_REPO=.
DST_DIR=../staging
ALEMBIC=false
CHANGELOG=false
COMMIT=false
TAG=false
PUSH=false
TARBALL=false
PATCHFILE=false
CLOSE_ISSUES=false
SIGN=false
FULL_MONTY=false
HELP=false
DRY_RUN=false
ECHO_CMD=

declare -a args
for a in "$@" ; do
	if [[ $a =~ --no-([^=]+)$ ]] ; then
		var=${BASH_REMATCH[1]//-/_}
		eval "${var^^}"="false"
	elif [[ $a =~ --([^=]+)=(.+)$ ]] ; then
		var=${BASH_REMATCH[1]//-/_}
		eval "${var^^}"="\"${BASH_REMATCH[2]}\""
	elif [[ $a =~ --([^=]+)$ ]] ; then
		var=${BASH_REMATCH[1]//-/_}
		eval "${var^^}"="true"
		${FULL_MONTY} && {
			ALEMBIC=true
			CHANGELOG=true
			COMMIT=true
			TAG=true
			PUSH=true
			TARBALL=true
			PATCHFILE=true
			SIGN=true
			CLOSE_ISSUES=true
		}
	else
		args+=( "$a" )
	fi
done

$HELP && print_help

IFS=\|
if [[ "start_tag" =~ ^(${needs[*]})$ ]] && [ -z "$START_TAG" ] ; then
	print_help "You must supply --start-tag=<tag>"
fi

if [[ "end_tag" =~ ^(${needs[*]})$ ]] && [ -z "$END_TAG" ] ; then
	print_help "You must supply --end-tag=<tag>"
fi

if [ ! -d "$SRC_REPO" ] ; then
	print_help "Source repository '$SRC_REPO' doesn't exist"
fi

if [ ! -d "$SRC_REPO/.git" ] ; then
	print_help "Source repository '$SRC_REPO' isn't a git repo"
fi

if [ ! -d "$DST_DIR" ] ; then
	print_help "Destination directory '$DST_DIR' doesn't exist"
fi

if [[ "start_tag" =~ ^(${tests[*]})$ ]] && [ -z "$(git -C ${SRC_REPO} tag -l ${START_TAG})" ] ; then
	bail "Start tag '${START_TAG}' doesn't exist"
fi

if [[ "start_tag" =~ ^(${tests[*]})$ ]] && [ -z "$(git -C ${SRC_REPO} tag -l ${END_TAG})" ] ; then
	bail "End tag '${END_TAG}' doesn't exist"
fi
unset IFS

SRC_REPO=$(realpath "$SRC_REPO")
DST_DIR=$(realpath "$DST_DIR")

$DRY_RUN && ECHO_CMD="echo"
