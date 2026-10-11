#!/bin/bash
# Writes commits to the project changelog in the maintainer's Obsidian vault.
# Shared version from claude-standards; copy it into each project unchanged.
#
#   wiki-sync.sh              adds every commit reachable from HEAD that is
#                             not in the changelog yet (idempotent)
#   wiki-sync.sh --rewritten  reads "old new" pairs (post-rewrite) from stdin,
#                             removes the entries of the replaced commits,
#                             then adds the missing ones
#
# Configuration (set by scripts/setup.sh):
#   wiki.vaultPath  vault root ($WIKI_VAULT_PATH overrides it)
#   wiki.project    folder below <vault>/Projekte/
#   wiki.prefix     marker prefix, e.g. "sdwm" for "%% sdwm:commits %%"
# Without them the script does nothing, so contributors are not affected.
#
# Runs as a Git hook after the commit and must never fail it: errors are
# printed as warnings, the exit code is always 0.

set -u

warn() {
    echo "wiki-sync: WARNING: $*" >&2
    echo "wiki-sync: changelog NOT updated. After fixing it: scripts/wiki-sync.sh" >&2
    exit 0
}

git rev-parse --verify -q HEAD >/dev/null || exit 0

vault="${WIKI_VAULT_PATH:-$(git config --get wiki.vaultPath)}"
project=$(git config --get wiki.project)
prefix=$(git config --get wiki.prefix)
[ -n "$vault" ] && [ -n "$project" ] && [ -n "$prefix" ] || exit 0

changelog="$vault/Projekte/$project/Changelog.md"
marker="%% $prefix:commits %%"

[ -f "$changelog" ] || warn "changelog not found: $changelog"
grep -qxF "$marker" "$changelog" || warn "marker '$marker' missing in $changelog"

# Commit links point to GitHub, derived from the remote "origin".
remote=$(git remote get-url origin 2>/dev/null)
case "$remote" in
    git@github.com:*) web="https://github.com/${remote#git@github.com:}" ;;
    https://github.com/*) web="$remote" ;;
    *) web="" ;;
esac
web="${web%.git}"

tmpdir=$(mktemp -d) || warn "mktemp failed"
trap 'rm -rf "$tmpdir"' EXIT
work="$tmpdir/changelog.md"
cp "$changelog" "$work" || warn "changelog not readable"

# Remove entries of replaced commits (amend, rebase).
if [ "${1:-}" = "--rewritten" ]; then
    awk -v p="$prefix" '{ print "(" p ":" $1 ")" }' > "$tmpdir/old"
    if [ -s "$tmpdir/old" ]; then
        grep -vF -f "$tmpdir/old" "$work" > "$tmpdir/filtered"
        mv "$tmpdir/filtered" "$work"
    fi
fi

# Every entry ends with an invisible marker "%% (<prefix>:<hash>) %%".
grep -o "($prefix:[0-9a-f]\{40\})" "$work" | sed "s/^($prefix://; s/)\$//" > "$tmpdir/known"
git log --format=%H HEAD | grep -vxF -f "$tmpdir/known" > "$tmpdir/missing"

: > "$tmpdir/entries"
while read -r hash; do
    IFS=$'\t' read -r date short subject author < <(git log -1 --date=short --format=$'%ad\t%h\t%s\t%an' "$hash")
    if [ -n "$web" ]; then
        ref="[\`$short\`]($web/commit/$hash)"
    else
        ref="\`$short\`"
    fi
    files=$(git show --name-only --format= "$hash" | awk '
        NF { n++; if (n <= 5) list = list (n > 1 ? ", " : "") "`" $0 "`" }
        END { if (n > 5) list = list " and " n - 5 " more"; print list }')
    line="- $date $ref $subject ($author)"
    [ -n "$files" ] && line="$line. Files: $files"
    echo "$line %% ($prefix:$hash) %%" >> "$tmpdir/entries"
done < "$tmpdir/missing"

if [ ! -s "$tmpdir/entries" ] && cmp -s "$work" "$changelog"; then
    exit 0
fi

# Insert new entries right below the marker (newest first).
awk -v marker="$marker" -v entries="$tmpdir/entries" '
    { print }
    $0 == marker && !done { while ((getline l < entries) > 0) print l; done = 1 }
' "$work" > "$tmpdir/new" || warn "insert failed"

# Overwrite the content instead of replacing the file, so iCloud and Obsidian keep the same file.
cat "$tmpdir/new" > "$changelog" || warn "write failed: $changelog"
count=$(wc -l < "$tmpdir/entries" | tr -d ' ')
echo "wiki-sync: changelog updated (new entries: $count)."
