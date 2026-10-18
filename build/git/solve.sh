#!/bin/sh
# The lab's self-check / solver for the Duchess objective, run by Isoloom as an in-machine `exec`
# check (inside the git container, which has git, curl and the served repo). It walks the intended
# path a player takes and asserts it still works, so a learner whose box broke is told to reset it.
#
# Exit 0 = solvable. It proves the leaked PyPI token is recoverable from the repository's git
# history and is gone from the current tip — but it never prints the token (that is the answer).
set -eu

BASE="${DUCHESS_BASE_URL:-http://127.0.0.1:3000}"
CLONE="$(mktemp -d)"
trap 'rm -rf "$CLONE"' EXIT

fail() { echo "FAIL: $1" >&2; exit 1; }

# 1. The repository clones over HTTP (so it is browseable), the way the hint tells the player to.
git -c advice.detachedHead=false clone -q "$BASE/duchess.git" "$CLONE" \
  || fail "could not clone $BASE/duchess.git"

# 2. The current tip is clean: .pypirc is no longer tracked (the "fix" that left history exposed).
if git -C "$CLONE" cat-file -e 'HEAD:.pypirc' 2>/dev/null; then
  fail "the token is still present at the tip; it should only survive in history"
fi

# 3. A past commit still carries .pypirc: find the newest commit that has it, and read the token
#    (the password line). This is exactly what a secret scanner (e.g. gitleaks) would surface.
leak_commit=''
for c in $(git -C "$CLONE" rev-list --all); do
  if git -C "$CLONE" cat-file -e "$c:.pypirc" 2>/dev/null; then
    leak_commit="$c"
    break
  fi
done
[ -n "$leak_commit" ] || fail "no commit in history carries .pypirc; nothing leaked"

token="$(git -C "$CLONE" show "$leak_commit:.pypirc" \
         | sed -n 's/^[[:space:]]*password[[:space:]]*=[[:space:]]*//p')"
[ -n "$token" ] || fail "the leaked .pypirc has no upload token"

# A short, non-sensitive note: the leaking commit (short) and the token's length only, never its
# value.
short="$(printf '%s' "$leak_commit" | cut -c1-10)"
echo "OK: token recoverable from history at commit $short (${#token} chars), absent from the tip" >&2
exit 0
