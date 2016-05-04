#!/bin/sh
set -e

rsync -rq --ignore-existing ${NEXUS_HOME}/etc/ /etc/sonatype/nexus
gosu nexus ${NEXUS_HOME}/bin/nexus run

exec "$@"
