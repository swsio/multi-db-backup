FROM alpine:3.13
LABEL maintainer="Florian Froehlich (florian.froehlich@sws.de)"

### Set Environment Variables
ENV MSSQL_VERSION=17.5.2.1-1 \
    TIMEZONE=Europe/Berlin

### Add core utils
RUN apk update && \
        apk upgrade && \
        apk add \
            iputils \
            bash \
            pcre \
            libssl1.1 && \
     apk add -t .base-rundeps \
            bash \
            busybox-extras \
            curl \
            grep \
            less \
            logrotate \
            nano \
            sudo \
            htop \
            tzdata \
            vim \
            && \
    rm -rf /var/cache/apk/* && \
    rm -rf /etc/logrotate.d/acpid && \
    rm -rf /root/.cache /root/.subversion && \
    \
    ## Quiet down sudo
    echo "Set disable_coredump false" > /etc/sudo.conf && \
    \
### Clean up
    rm -rf /usr/src/*&& \
    \
    ### Dependencies
    set -ex && \
    apk update && \
    apk upgrade && \
    apk add -t .db-backup-build-deps \
               build-base \
               bzip2-dev \
               git \
               libarchive-dev \
               xz-dev \
               && \
    \
    apk add --no-cache -t .db-backup-run-deps \
      	       bzip2 \
               influxdb \
               libarchive \
               mariadb-client \
               mongodb-tools \
               libressl \
               pigz \
               postgresql \
               postgresql-client \
               redis \
               sqlite \
               xz \
               zstd \
               && \
    \
    cd /usr/src && \
    \
    apkArch="$(apk --print-arch)"; \
    case "$apkArch" in \
	x86_64) mssql=true ; curl -O https://download.microsoft.com/download/e/4/e/e4e67866-dffd-428c-aac7-8d28ddafb39b/msodbcsql17_${MSSQL_VERSION}_amd64.apk ; curl -O https://download.microsoft.com/download/e/4/e/e4e67866-dffd-428c-aac7-8d28ddafb39b/mssql-tools_${MSSQL_VERSION}_amd64.apk ; echo y | apk add --allow-untrusted msodbcsql17_${MSSQL_VERSION}_amd64.apk mssql-tools_${MSSQL_VERSION}_amd64.apk ;; \
	*) echo >&2 "Detected non x86_64 build variant, skipping MSSQL installation" ;; \
    esac; \
    mkdir -p /usr/src/pbzip2 && \
    curl -sSL https://launchpad.net/pbzip2/1.1/1.1.13/+download/pbzip2-1.1.13.tar.gz | tar xvfz - --strip=1 -C /usr/src/pbzip2 && \
    cd /usr/src/pbzip2 && \
    make && \
    make install && \
    mkdir -p /usr/src/pixz && \
    curl -sSL https://github.com/vasi/pixz/releases/download/v1.0.7/pixz-1.0.7.tar.xz | tar xvfJ - --strip 1 -C /usr/src/pixz && \
    cd /usr/src/pixz && \
    ./configure \
        --prefix=/usr \
        --sysconfdir=/etc \
        --localstatedir=/var \
        && \
     make && \
     make install && \
     \
### Cleanup
    apk del .db-backup-build-deps && \
    rm -rf /usr/src/* && \
    rm -rf /tmp/* /var/cache/apk/* && \
# Add coreutils
    apk add --update coreutils && rm -rf /var/cache/apk/* && \
    \
### Add timezone
    cp -R /usr/share/zoneinfo/${TIMEZONE} /etc/localtime && \
    echo "${TIMEZONE}" > /etc/timezone

### Add s3cmd
RUN apk add --no-cache python2 && \
    python -m ensurepip && \
    rm -r /usr/lib/python*/ensurepip && \
    pip install --upgrade pip setuptools && \
    rm -r /root/.cache && \
    pip install python-dateutil python-magic && \
    S3CMD_CURRENT_VERSION=`curl -fs https://api.github.com/repos/s3tools/s3cmd/releases/latest | grep tag_name | sed -E 's/.*"v?([0-9\.]+).*/\1/g'` \
    && mkdir -p /opt \
    && wget https://github.com/s3tools/s3cmd/releases/download/v${S3CMD_CURRENT_VERSION}/s3cmd-${S3CMD_CURRENT_VERSION}.zip \
    && unzip s3cmd-${S3CMD_CURRENT_VERSION}.zip -d /opt/ \
    && ln -s $(find /opt/ -name s3cmd) /usr/bin/s3cmd \
    && ls /usr/bin/s3cmd



### Setup
ADD install  /

### Add user
RUN adduser -S backup --home /home/backup --uid 1001        && \
    mkdir -p "/usr/local/backup"                            && \
    mkdir -p "/tmp/backups"                                 && \
    chown -R backup:0 /usr/local/backup                     && \
    chown backup:0 /usr/local/bin/db-backup                 && \
    chown backup:0 /usr/local/bin/backup-now                && \
    chown backup:0 /usr/local/bin/clean-s3                  && \
    chown backup:0 -R /assets                               && \
    chown backup:0 -R /tmp/backups                          && \
    chmod -R g=u /usr/local/backup                          && \
    chmod -R g=u /tmp/backups                               && \
    chmod -R g=u /assets                                    && \
    chown backup:0 -R /etc/localtime                        && \
    chmod -R g=u /etc/localtime                             && \
    chown backup:0 -R /etc/timezone                         && \
    chmod -R g=u /etc/timezone                              

#RUN chown backup:0 -R
#RUN chmod -R g=u 


COPY docker-entrypoint.sh /docker-entrypoint.sh

##Specify the user with UID
USER 1001

ENTRYPOINT ["/docker-entrypoint.sh"]

STOPSIGNAL SIGQUIT

VOLUME /backup /tmp/backups

CMD ["bash", "db-backup"]
