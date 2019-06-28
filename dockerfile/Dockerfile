FROM debian:jessie-slim
MAINTAINER Kyle

ENV DEBIAN_FRONTEND=noninteractive
COPY jq /usr/bin/jq
COPY entrypoint.sh /entrypoint.sh
RUN groupadd -g 999 mysql && \
    useradd -u 999 -r -g 999 -s /sbin/nologin -c "Default Application User" mysql && \
    apt-get update -qq && apt-get install -qqy --no-install-recommends apt-transport-https ca-certificates pwgen wget vim iproute2 telnet && \
    wget https://repo.percona.com/apt/percona-release_0.1-7.jessie_all.deb && dpkg -i percona-release_0.1-7.jessie_all.deb && \
    apt-get update -qq  && apt-get install -qqy --force-yes percona-xtradb-cluster-57 curl xinetd && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /var/lib/mysql && \
    mkdir -p /var/lib/mysql /var/run/mysqld  && \
    chown -R mysql:mysql /var/lib/mysql /var/run/mysqld && \
    chmod 777 /var/run/mysqld && \
    chmod a+x /usr/bin/jq && \
    echo "pxccheck	19200/tcp	#pxccheck" >>/etc/services && \
    rm -f /etc/xinetd.d/mysqlchk
COPY pxccheck /etc/xinetd.d/pxccheck

ENV COLUMNS `tput cols`
ENV LINES `tput lines`
RUN echo "alias ls='ls --color=auto' 2>/dev/null" >>/etc/bash.bashrc && \
    echo "export PS1='[\[\e[31;1m\]\u\[\e[0m\]@\[\e[36;1m\]\h\[\e[0m\]:\[\e[34;4;1m\]\w\[\e[0m\]]\[\e[33;1m\]\$\[\e[0m\] '" >>/etc/bash.bashrc
USER 999
VOLUME ["/var/lib/mysql", "/var/log/mysql"]
ENTRYPOINT ["/entrypoint.sh"]
EXPOSE 3306 4444 4567 4568 19200
