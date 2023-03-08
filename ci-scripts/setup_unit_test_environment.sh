
prenv() {
	v=$1
	echo "$v: ${!v}"
}

prenv GH_TOKEN
prenv PR_NUMBER
prenv PR_REPO
prenv GITHUB_EVENT_PATH

gh api repos/asterisk/asterisk-gh-test/pulls/${PR_NUMBER} | jq . > pr.json
gh api repos/asterisk/asterisk-gh-test/pulls/${PR_NUMBER}/commits | jq . > commits.json

REPO_DIR=${PR_REPO##*/}
PR_SHA=$(jq -r '.merge_commit_sha' pr.json)

echo "PR_NUMBER=$PR_NUMBER" >> $GITHUB_ENV
echo "PR_REF=$PR_REF" >> $GITHUB_ENV
echo "PR_REPO=$PR_REPO" >> $GITHUB_ENV
echo "GITHUB_REPOSITORY=$PR_REPO" >> $GITHUB_ENV
echo "REPO_DIR=$REPO_DIR" >> $GITHUB_ENV
echo "PR_SHA=$PR_SHA" >> $GITHUB_ENV

jq '.event.client_payload' $GITHUB_EVENT_PATH > pr_event.json

echo "::group::pr.json"
cat pr.json
echo "::endgroup::"

echo "::group::commits.json"
cat commits.json
echo "::endgroup::"

echo "::group::gh_event.json"
jq . $GITHUB_EVENT_PATH
echo "::endgroup::"

echo "::group::pr_event.json"
cat pr_event.json
echo "::endgroup::"
