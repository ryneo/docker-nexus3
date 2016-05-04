# sonatype/nexus3

A Dockerfile for Sonatype Nexus Repository Manager 3, based on CentOS.

To run, binding the exposed port 8081 to the host.

```
$ docker run -d -p 8081:8081 -p 8443:8443 --name nexus sonatype/nexus3
```

To test:

```
$ curl -u admin:admin123 http://localhost:8081/service/metrics/ping
```

To (re)build the image:

Copy the Dockerfile and do the build-

```
$ docker build --rm=true --tag=sonatype/nexus3 .
```


## Notes

* Default credentials are: `admin` / `admin123`

* It can take some time (2-3 minutes) for the service to launch in a
new container.  You can tail the log to determine once Nexus is ready:

```
$ docker logs -f nexus
```

* Installation of Nexus is to `/opt/sonatype/nexus`.  

* A persistent directory, `/nexus-data`, is used for configuration,
logs, and storage.

* `/etc/sonatype/nexus` is used for configuration files

* Three environment variables can be used to control the JVM arguments

  * `JAVA_MAX_HEAP`, passed as -Xmx.  Defaults to `1200m`.

  * `JAVA_MIN_HEAP`, passed as -Xms.  Defaults to `1200m`.

  * `EXTRA_JAVA_OPTS`.  Additional options can be passed to the JVM via
  this variable.

  These can be used supplied at runtime to control the JVM:

  ```
  $ docker run -d -p 8081:8081 --name nexus -e JAVA_MAX_HEAP=768m sonatype/nexus3
  ```

## Configure HTTPS

1. Add `${karaf.etc}/jetty-https.xml` to `nexus-args` in `org.sonatype.nexus.cfg`.

1. Add `application-port-ssl=8443` to `org.sonatype.nexus.cfg`.

1. Generate self-signed server certificate.

  ```
  keytool -genkeypair -keystore server-keystore.jks -storepass changeit -keypass changeit -alias jetty -keyalg RSA -keysize 2048 -validity 5000 -dname "CN=*.${NEXUS_DOMAIN}, OU=Example, O=Sonatype, L=Unspecified, ST=Unspecified, C=US" -ext "SAN=DNS:${NEXUS_DOMAIN},IP:${NEXUS_IP_ADDRESS}" -ext "BC=ca:true"
  ```

1. Set `TrustStorePath` and `KeyStorePath` in `jetty-https.xml`.

1. Set passwords for `KeyStorePassword`, `KeyManagerPassword` and `TrustStorePassword`.

### Persistent Data

There are two general approaches to handling persistent storage requirements
with Docker. See [Managing Data in Containers](https://docs.docker.com/userguide/dockervolumes/)
for additional information.

  1. *Use a data volume container*.  Since data volumes are persistent
  until no containers use them, a container can created specifically for
  this purpose.  This is the recommended approach.  

  ```
  $ docker run -d --name nexus-data sonatype/nexus3 echo "data-only container for Nexus"
  $ docker run -d -p 8081:8081 --name nexus --volumes-from nexus-data sonatype/nexus3
  ```

  2. *Mount a host directory as the volume*.  This is not portable, as it
  relies on the directory existing with correct permissions on the host.
  However it can be useful in certain situations where this volume needs
  to be assigned to certain specific underlying storage.  

  ```
  $ mkdir -p /some/dir/nexus-data && mkdir -p /some/dir/nexus-config
  $ docker run -d -p 8081:8081 --name nexus -v /some/dir/nexus-data:/nexus-data -v /some/dir/nexus-config:/etc/sonatype/nexus sonatype/nexus3
  ```
