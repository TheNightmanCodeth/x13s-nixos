#!/usr/bin/env nix-shell
#! nix-shell -i bash
#! nix-shell -p bash curl jq

extract_maj() {
	branch=$1
    # Extract major/minor/rc versions
    regex="s/.*sc8280xp-([0-9]+)\.([0-9]+)-rc([0-9]+)$/"
    major=$(echo "$branch" | sed -E "${regex}\1/")
	echo $major
}

extract_min() {
	branch=$1
    # Extract major/minor/rc versions
    regex="s/.*sc8280xp-([0-9]+)\.([0-9]+)-rc([0-9]+)$/"
    minor=$(echo "$branch" | sed -E "${regex}\2/")
	echo $minor
}

extract_rc() {
	branch=$1
    # Extract major/minor/rc versions
    regex="s/.*sc8280xp-([0-9]+)\.([0-9]+)-rc([0-9]+)$/"
    rc=$(echo "$branch" | sed -E "${regex}\3/")
	echo $rc
}


# Function to extract version numbers from branch name
extract_version() {
    branch=$1
	major=$(extract_maj $branch)
	minor=$(extract_min $branch)
	rc=$(extract_rc $branch)

    # Validate the results are numbers and are not null
    if [ "$major" -eq "$major" ] 2>/dev/null && \
       [ "$minor" -eq "$minor" ] 2>/dev/null; then
    # If we don't have an RC, it's newer than any rc versions
	if ! [ "$rc" -eq "$rc" ] 2>/dev/null; then
		rc=99
	fi
	printf "%03d%03d%03d" "$major" "$minor" "$rc"
    else
	printf "000000000" # Return lowest possible value for invalid formats
    fi
}

flake_regex="s/.*jhovold\/linux\/(wip\/.+)\";$/"

update_flake() {
	major=$(extract_maj $1)
	minor=$(extract_min $1)
	rc=$(extract_rc $1)

	sed -ri "${flake_regex}\      url = \"github:jhovold\/linux\/${1//\//\\/}\";/" flake.nix
	if [ $rc -eq 99 ]; then
        sed -ri "s/.*version = \"(.*)\";$/\    version = \"${major//\//\\/}\.${minor//\//\\/}.0\";/" flake.nix
	else
		sed -ri "s/.*version = \"(.*)\";$/\    version = \"${major//\//\\/}\.${minor//\//\\/}.0-rc${rc//\//\\/}\";/" flake.nix
	fi

	nix flake update
}

BRANCHES=$(curl -L https://api.github.com/repos/jhovold/linux/branches | jq -r '.[]|select(.name | contains("wip/sc8280xp")).name')

current_branch=$(cat flake.nix | sed -rn "${flake_regex}\1/p")
current_version=$(extract_version $current_branch)
highest_branch=""
highest_version="000000000"

for branch in $BRANCHES; do
    # Skip empty lines
    [ -z "$branch" ] && continue
    version=$(extract_version "$branch")

    # Compare versions as strings (padded numbers make this work)
    if [ $version -gt $current_version ] && [ $version -gt $highest_version ]; then
        highest_version=$version
	    highest_branch=$branch
    fi
done

[ -n "$highest_branch" ] && echo "Updating to $highest_branch"; update_flake $highest_branch
