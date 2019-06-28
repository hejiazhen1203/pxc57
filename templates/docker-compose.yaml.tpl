version: '2'
services:
  pxc-_NODE_:
    restart: always
    image: pxc57:20190625
    hostname: pxc-_NODE_
    container_name: pxc-_NODE_
    environment:
      TZ: Asia/Shanghai
      LANG: C.UTF-8
    ports:
      - 3306:3306
      - 4444:4444
      - 4567:4567
      - 4568:4568
      - 19200:19200
    volumes:
      - _WORKDIR_/conf/pxc-_NODE_.cnf:/etc/mysql/my.cnf
      - _WORKDIR_/conf/.pxc-_NODE__runtime.env:/.app_runtime.env
      - _DATADIR_/pxc-cluster/pxc-_NODE_/data:/var/lib/mysql
      - _DATADIR_/pxc-cluster/pxc-_NODE_/log:/var/log/mysql

