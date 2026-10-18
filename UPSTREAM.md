# Upstream

This lab reproduces one challenge — **Duchess** — from CI/CD Goat.

| What | Source | Licence |
| --- | --- | --- |
| The "Duchess" challenge (a PyPI token leaked in a repository's git history) | [CI/CD Goat](https://github.com/cider-security-research/cicd-goat) by Cider Security (now Palo Alto Networks), v1.2.7 | Apache-2.0 |
| Security class | [OWASP CICD-SEC-6: Insufficient Credential Hygiene](https://owasp.org/www-project-top-10-ci-cd-security-risks/CICD-SEC-06-Insufficient-Credential-Hygiene) | — |

Only the *vulnerability* is reproduced, not upstream's eight-machine CI/CD stack: a single
lightweight git server serves one repository whose history leaks the token.

Nothing is vendored from upstream. Upstream's Duchess serves a copy of the PyJWT project (MIT)
with the token committed to its `.pypirc`, and bakes one fixed token into the challenge. This lab
instead ships an **original** sample package (`build/git/repo-src/`, authored here, no third-party
code) and seeds a **per-player** token into its history at run time, so each player recovers their
own flag and nothing but the challenge idea comes from upstream.
