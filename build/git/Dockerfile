# The Wonderland git server: nginx serving a bare repository over HTTP (the git "dumb" protocol,
# enough to clone and browse history), with git and curl for the in-machine solver check. The
# leaked token is NOT in this image: it arrives at run time as a file and the setup job seeds it
# into the repo's history on the shared volume.
# alpine:3.19, pinned to its multi-arch digest as resolved on 2026-11-11.
FROM alpine:3.19@sha256:6baf43584bcb78f2e5847d1de515f23499913ac9f12bdf834811a3145eb11ca1

RUN apk add --no-cache nginx git curl \
 && mkdir -p /srv/git /run/nginx /opt/duchess

# The repository's source files (everything but the per-player secret), baked in so the setup job
# — which runs this same image — can build the history from them.
COPY repo-src/ /opt/duchess/repo-src/

COPY nginx.conf /etc/nginx/nginx.conf
COPY solve.sh /usr/local/bin/duchess-solve
RUN chmod 0755 /usr/local/bin/duchess-solve

EXPOSE 3000
CMD ["nginx", "-g", "daemon off;"]
