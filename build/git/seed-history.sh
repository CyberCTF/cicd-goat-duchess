#!/bin/sh
# Builds the Wonderland/duchess repository's history into the served volume, with this player's
# PyPI upload token leaked in a past commit and removed at the tip. Runs as an Isoloom `setup`
# script: on containers a one-shot job of the git machine's image, sharing its network namespace,
# its named volume (/srv/git) and its files (the per-player flag at /run/lab/duchess).
#
# The token arrives as a FILE (isoloom.yml `files: [{ input: CTF_FLAG_DUCHESS }]`), never an
# environment variable, so it never shows in `docker inspect`. When the file is empty (an offline
# start — local, CI) the development placeholder is used instead, so the lab still comes up and is
# solvable without a launcher. The repository's source files are baked into the image at
# /opt/duchess/repo-src; only the token is per-player.
set -eu

TOKEN_FILE="${DUCHESS_TOKEN_FILE:-/run/lab/duchess}"
SRC="${DUCHESS_SRC:-/opt/duchess/repo-src}"
REPO_DIR="${DUCHESS_REPO_DIR:-/srv/git/duchess.git}"

# Development placeholder. Kept in sync with .ctf/objectives.json `dev`. Never a real per-player
# value: it is a syntactically valid but inert PyPI token.
DEV_TOKEN='pypi-AgEIcHlwaS5vcmcCJGR1Y2hlc3MtZGV2LW9ubHktbm90LWEtcmVhbC1zZWNyZXQAAAACg'

read_token() {  # $1 = file, $2 = development placeholder
  if [ -s "$1" ]; then
    tr -d '\r\n' < "$1"
  else
    printf '%s' "$2"
  fi
}

TOKEN="$(read_token "$TOKEN_FILE" "$DEV_TOKEN")"
[ -n "$TOKEN" ] || { echo "seed: the token is empty" >&2; exit 1; }

# A PyPI token is one line; refuse a value with a newline (which would break the .pypirc line and
# split the secret across the history). CyberCTF's SECRET alphabet has none.
case "$TOKEN" in
  *"
"*) echo "seed: refusing a token that contains a newline" >&2; exit 1 ;;
esac

# Commit identities and fixed dates, so the history reads like a real project's.
export GIT_AUTHOR_NAME='Duchess' GIT_AUTHOR_EMAIL='duchess@wonderland.example'
export GIT_COMMITTER_NAME='Duchess' GIT_COMMITTER_EMAIL='duchess@wonderland.example'
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null
commit() {  # $1 = date, $2 = message
  GIT_AUTHOR_DATE="$1" GIT_COMMITTER_DATE="$1" git commit -q -m "$2"
}

# A fresh build every start: the per-player token changes between players.
rm -rf "$REPO_DIR"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

git -c init.defaultBranch=main init -q "$WORK"
cd "$WORK"
git config gc.auto 0   # keep objects as git writes them; no surprise repack

# 1. The project skeleton (package, module, tests).
cp "$SRC/README.md" "$SRC/pyproject.toml" .
mkdir -p duchess tests
cp "$SRC/duchess/__init__.py" duchess/
cp "$SRC/duchess/core.py" duchess/
cp "$SRC/tests/test_core.py" tests/
git add -A
commit '2024-01-08T09:14:00' 'Initial project skeleton for the duchess package'

# 2. A GitHub Actions workflow that publishes the package to PyPI on a tag.
mkdir -p .github/workflows
cp "$SRC/.github/workflows/publish.yml" .github/workflows/
git add -A
commit '2024-02-19T16:02:00' 'Add PyPI publish workflow'

# 3. THE LEAK: a .pypirc with the real upload token committed by accident, so `twine upload` could
#    be run by hand. The token is this player's flag.
{
  printf '%s\n' '[distutils]'
  printf '%s\n' 'index-servers ='
  printf '%s\n\n' '    pypi'
  printf '%s\n' '[pypi]'
  printf '%s\n' 'repository = https://upload.pypi.org/legacy/'
  printf '%s\n' 'username = __token__'
  printf 'password = %s\n' "$TOKEN"
} > .pypirc
git add -A
commit '2024-03-04T11:47:00' 'Add release upload credentials (quick manual twine upload)'

# 4. THE (INCOMPLETE) FIX: stop tracking .pypirc and ignore it — but the token stays in the history
#    above, reachable to anyone who can read the repo. This is CICD-SEC-6.
git rm -q --cached .pypirc
rm -f .pypirc
cp "$SRC/.gitignore" .
git add -A
commit '2024-03-04T12:05:00' 'Stop committing .pypirc; move release token to CI secrets'

# 5. Ordinary work continues on top, so the tip looks clean.
sed -i 's/^version = "0\.1\.0"/version = "0.2.0"/' pyproject.toml
sed -i "s/^__version__ = \"0\.1\.0\"/__version__ = \"0.2.0\"/" duchess/__init__.py
git add -A
commit '2024-05-21T10:30:00' 'Release 0.2.0'

# Publish as a bare repository nginx can serve, with the dumb-HTTP index (info/refs, objects/info)
# written so `git clone` works over plain HTTP.
git clone -q --bare "$WORK" "$REPO_DIR"
git -C "$REPO_DIR" --bare update-server-info
# A bare repo cloned from a non-bare one keeps origin; drop it so the served repo is self-contained.
git -C "$REPO_DIR" remote remove origin 2>/dev/null || true
chmod -R a+rX "$REPO_DIR"

echo "seed: duchess repository published at $REPO_DIR ($(git -C "$REPO_DIR" rev-list --count HEAD) commits)"
