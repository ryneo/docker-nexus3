FROM       centos:centos7
MAINTAINER Sonatype <cloud-ops@sonatype.com>

ENV NEXUS_HOME=/opt/sonatype/nexus \
    NEXUS_DATA=/nexus-data \
    NEXUS_VERSION=3.0.0-03 \
    JAVA_HOME=/opt/java \
    JAVA_VERSION_MAJOR=8 \
    JAVA_VERSION_MINOR=77 \
    JAVA_VERSION_BUILD=03 \
    JAVA_MAX_MEM=1200m \
    JAVA_MIN_MEM=1200m \
    EXTRA_JAVA_OPTS=""

ADD entrypoint.sh /bin/entrypoint.sh
RUN chmod +x /bin/entrypoint.sh

RUN yum install -y \
  curl rsync tar \
  && yum clean all

RUN gpg --keyserver pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
    && curl -o /usr/local/bin/gosu -SL "https://github.com/tianon/gosu/releases/download/1.8/gosu-amd64" \
    && curl -o /usr/local/bin/gosu.asc -SL "https://github.com/tianon/gosu/releases/download/1.8/gosu-amd64.asc" \
    && gpg --verify /usr/local/bin/gosu.asc \
    && rm /usr/local/bin/gosu.asc \
    && rm -r /root/.gnupg/ \
    && chmod +x /usr/local/bin/gosu

# install Oracle JRE
RUN mkdir -p /opt \
  && curl --fail --silent --location --retry 3 \
  --header "Cookie: oraclelicense=accept-securebackup-cookie; " \
  http://download.oracle.com/otn-pub/java/jdk/${JAVA_VERSION_MAJOR}u${JAVA_VERSION_MINOR}-b${JAVA_VERSION_BUILD}/server-jre-${JAVA_VERSION_MAJOR}u${JAVA_VERSION_MINOR}-linux-x64.tar.gz \
  | gunzip \
  | tar -x -C /opt \
  && ln -s /opt/jdk1.${JAVA_VERSION_MAJOR}.0_${JAVA_VERSION_MINOR} ${JAVA_HOME}

RUN groupadd -g 1000 nexus \
  && useradd -u 1000 -g 1000 -m -d "${NEXUS_DATA}" -s /bin/bash nexus

# install nexus
RUN mkdir -p "${NEXUS_HOME}" \
  && curl --fail --silent --location --retry 3 \
    https://download.sonatype.com/nexus/3/nexus-${NEXUS_VERSION}-unix.tar.gz \
  | gunzip \
  | tar x -C /opt/sonatype/nexus --strip-components=1 nexus-${NEXUS_VERSION} \
  && chown -R nexus "${NEXUS_HOME}" \
  && mkdir -p /etc/sonatype/nexus \
  && chown -R nexus /etc/sonatype/nexus

## configure nexus runtime env
RUN sed \
    -e "s|karaf.home=.|karaf.home=${NEXUS_HOME}|g" \
    -e "s|karaf.base=.|karaf.base=${NEXUS_HOME}|g" \
    -e "s|karaf.etc=etc|karaf.etc=/etc/sonatype/nexus|g" \
    -e "s|java.util.logging.config.file=etc|java.util.logging.config.file=/etc/sonatype/nexus|g" \
    -e "s|karaf.data=data|karaf.data=${NEXUS_DATA}|g" \
    -e "s|java.io.tmpdir=data/tmp|java.io.tmpdir=${NEXUS_DATA}/tmp|g" \
    -i ${NEXUS_HOME}/bin/nexus.vmoptions

VOLUME ${NEXUS_DATA} /etc/sonatype/nexus

EXPOSE 8081 8443 5000
WORKDIR /opt/sonatype/nexus

# Run script to copy config and start nexus
ENTRYPOINT ["/bin/entrypoint.sh"]
