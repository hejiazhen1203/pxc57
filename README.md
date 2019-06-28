####	说明

该脚本实现基于docker部署Percona XtraDB Cluster 5.7集群，默认为三节点，可根据需求修改脚本，pxc镜像的Dockerfile也可根据自己需求改动。

####	使用

1. 使用Dockerfile构建出镜像

   ```	bash
   cd dockerfile/
   docker build -t pxc57:20190625 .
   ```

2. 编辑配置文件

   ```	bash
   cp pxc-cluster.conf.tpl pxc-cluster.conf
   vim pxc-cluster.conf
   #根据提示填写以下相关内容
   # 集群名称
   export CLUSTER_NAME="pxc-cluster1"
   
   # 节点1 主机内网IP
   export NODE1_HOST=""
   
   # 节点2 主机内网IP
   export NODE2_HOST=""
   
   # 节点3 主机内网IP
   export NODE3_HOST=""
   
   # 数据存储目录
   export DATA_DIR=""
   
   # 数据库初始root密码
   export MYSQL_ROOT_PASSWORD=""
   ```

3. 部署

      ※ 注：部署或者后面启动第一个节点的时候都需要加上参数：--bootstrap

      ```	bash
      # 第一个节点，需要最后加--bootstrap
      ./op.sh install node1 --bootstrap
      # 第二个节点
      ./op.sh install node2
      # 第三个节点
      ./op.sh install node3
      
      # 检查容器状态或pxc节点状态
      ./op.sh status node2
      ./op.sh check node2
      ```

4. 验证

5. 下一步，使用xinetd配置健康检查服务(/usr/bin/clustercheck)，然后前端使用haproxy代理并httpchk