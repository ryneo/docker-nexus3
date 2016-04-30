#!/bin/sh
set -e

gosu root cp ${NEXUS_HOME}/etc/* /etc/sonatype/nexus

exec "$@"
