#!/bin/bash
## -------------------------------------------------------------------------
export PATH=/sbin:/usr/sbin:/usr/local/sbin:/usr/local/bin:/usr/bin:/bin
export TERM="xterm-256color"

export WORKDIR="$( cd $(dirname "$0") &&  pwd )"
cd "${WORKDIR}" || exit 1
## -------------------------------------------------------------------------
info() {
    date +"$( tput bold ; tput setaf 2)%F %T Info: $@$( tput sgr0)"
}

warn() {
    date +"$( tput bold ; tput setaf 3)%F %T Warning: $@$( tput sgr0)"
}

error() {
    date +"$( tput bold ; tput setaf 1)%F %T Error: $@$( tput sgr0)"
}

err_exit() {
    date +"$( tput bold ; tput setaf 1)%F %T Error: $@$( tput sgr0)"
    exit 1
}

help_msg() {
     echo -e "Usage: "
     echo -e "      安装: ./op.sh install [node1|node2|node3] [--bootstrap]"
     echo -e "      启动: ./op.sh start [node1|node2|node3] [--bootstrap]"
     echo -e "      说明: 安装或启动整个集群的第一个节点的时候必须加上参数 --bootstrap,其他节点不能加此参数"
     echo -e "      停止: ./op.sh stop [node1|node2|node3]"
     echo -e "      status      检查容器的状态"
     echo -e "      check       检查节点的状态"
     echo -e "      clear [node1|node2|node3]  *危险操作* 清除 所选节点 容器及所有数据"
}
## -------------------------------------------------------------------------
_check() {
    local _role="$1"
    docker exec -i "pxc-${_role}" mysql -uroot -p -h127.0.0.1 -e "show status where variable_name REGEXP 'wsrep_ready|wsrep_cluster_status|wsrep_cluster_size|wsrep_local_state_comment|wsrep_incoming_addresses';"
}

_status() {
    local _role="$1"
    docker-compose -f "${WORKDIR}"/pxc-"${_role}".yaml ps
}

_install() {
    local _role="$1"
    image_count=`docker image ls pxc57:20190625 | wc -l`
    if [ ${image_count} -le 1 ];then
        info "导入镜像: pxc57:20190625"
        docker load -i "${WORKDIR}/images/pxc57_image.tar.gz"
    fi
    if [ -z "$2" ];then
        _generate "${_role}" "false"
    else
        _generate "${_role}" "true" 
    fi
    docker-compose -f "${WORKDIR}"/pxc-"${_role}".yaml up -d
    if [ ! -z "$2" ];then
        sed -i 's#BOOTSTRAP=".*"#BOOTSTRAP="false"#g' "${WORKDIR}"/conf/.pxc-"${_role}"_runtime.env
    fi
}

_start() {
    local _role="$1"
    if [ -z "$2" ];then
        sed -i 's#BOOTSTRAP=".*"#BOOTSTRAP="false"#g' "${WORKDIR}"/conf/.pxc-"${_role}"_runtime.env
        docker-compose -f "${WORKDIR}"/pxc-"${_role}".yaml start
    else
        sed -i 's#BOOTSTRAP=".*"#BOOTSTRAP="true"#g' "${WORKDIR}"/conf/.pxc-"${_role}"_runtime.env
        docker-compose -f "${WORKDIR}"/pxc-"${_role}".yaml start
        sed -i 's#BOOTSTRAP=".*"#BOOTSTRAP="false"#g' "${WORKDIR}"/conf/.pxc-"${_role}"_runtime.env
    fi
}

_stop() {
    local _role="$1"
    docker-compose -f "${WORKDIR}"/pxc-"${_role}".yaml stop
}
_clear() {
    local _role="$1"
    warn "清除${_role}容器及其数据."
    docker-compose -f "${WORKDIR}"/pxc-"${_role}".yaml down
    rm -f "${WORKDIR}"/pxc-"${_role}".yaml
    rm -f "${WORKDIR}"/conf/pxc-"${_role}".cnf
    rm -f "${WORKDIR}"/conf/.pxc-"${_role}"_runtime.env
    rm -rf "${DATA_DIR}"/pxc-cluster/pxc-${_role}/
}

_generate(){
    local _role="$1"
    local _bootstrap="$2"
    local _id=$(echo "${_role:4}")
    local _host=$(eval echo '$NODE'"$_id"'_HOST')
    local _compose="${WORKDIR}"/pxc-"${_role}".yaml
    local _config="${WORKDIR}"/conf/pxc-"${_role}".cnf
    local _runtenv="${WORKDIR}"/conf/.pxc-"${_role}"_runtime.env
    if [[ ! -f "${WORKDIR}/templates/docker-compose.yaml.tpl" ]];then
        err_exit "模板文件不存在."
    fi

    mkdir -p "${DATA_DIR}"/pxc-cluster/pxc-${_role}/{data,log}
    chown -R 999.999 "${DATA_DIR}"/pxc-cluster/pxc-${_role}/
    sed -e "s#_NODE_#${_role}#g" \
        -e "s#_WORKDIR_#${WORKDIR}#g" \
        -e "s#_DATADIR_#${DATA_DIR}#g" "${WORKDIR}"/templates/docker-compose.yaml.tpl > "${_compose}"

    sed -e "s#_SERVER_ID_#${_id}#g" \
        -e "s#_NODE1_HOST_#${NODE1_HOST}#g" \
        -e "s#_NODE2_HOST_#${NODE2_HOST}#g" \
        -e "s#_NODE3_HOST_#${NODE3_HOST}#g" \
        -e "s#_CLUSTER_NAME_#${CLUSTER_NAME}#g" \
        -e "s#_NODE_NAME_#${_role}#g" \
        -e "s#_NODE_HOST_#${_host}#g" "${WORKDIR}"/templates/my.cnf.tpl > "${_config}"
    sed -e 's#MYSQL_ROOT_PASSWORD=".*"#MYSQL_ROOT_PASSWORD="'${MYSQL_ROOT_PASSWORD}'"#g'  \
        -e 's#BOOTSTRAP=".*"#BOOTSTRAP="'${_bootstrap}'"#g' "${WORKDIR}"/templates/app_runtime.env.tpl > "${_runtenv}"
}

## -------------------------------------------------------------------------
CONFIG="${WORKDIR}/pxc-cluster.conf"

if [[ ! -f ${CONFIG} ]] ; then
    err_exit "$( basename ${CONFIG} ) is not found!"
else
    . "${CONFIG}"
fi

exit_=false
var_arrs=(CLUSTER_NAME NODE1_HOST NODE2_HOST NODE3_HOST DATA_DIR MYSQL_ROOT_PASSWORD)
for var in ${var_arrs[@]}
do
    var2=`eval echo '$'"$var"`
    if [[ -z "${var2}" ]] ; then
        error "${var} is empty!"
        exit_=true
    fi
done
if ${exit_};then
    exit 2
fi

case "$1" in
    install )
        if [ "$2" = "node1" -o "$2" = "node2" -o "$2" = "node3" ];then
            if [ ! -z "$3" ];then
                if [ "$3" = "--bootstrap" ];then
                    _install "$2" "$3"
                else
                    echo "Usage:  $(basename $0) install [node1|node2|node3] [--bootstrap]" 
                fi
            else
                _install "$2"
            fi
        else
            echo "Usage:  $(basename $0) install [node1|node2|node3]"
        fi
    ;;
    start )
        if [ "$2" = "node1" -o "$2" = "node2" -o "$2" = "node3" ];then
            if [ ! -z "$3" ];then
                if [ "$3" = "--bootstrap" ];then
                    _start "$2" "$3"
                else
                    echo "Usage:  $(basename $0) start [node1|node2|node3] [--bootstrap]" 
                fi
            else
                _start "$2"
            fi
        else
            echo "Usage:  $(basename $0) start [node1|node2|node3]"
        fi
    ;;
    stop )
        if [ "$2" = "node1" -o "$2" = "node2" -o "$2" = "node3" ];then
            _stop "$2"
        else
            echo "Usage:  $(basename $0) stop [node1|node2|node3]"
        fi
    ;;
    status )
        if [ "$2" = "node1" -o "$2" = "node2" -o "$2" = "node3" ];then
            _status "$2"
        else
            echo "Usage:  $(basename $0) status [node1|node2|node3]"
        fi
    ;;
    check )
        if [ "$2" = "node1" -o "$2" = "node2" -o "$2" = "node3" ];then
            _check "$2"
        else
            echo "Usage:  $(basename $0) check [node1|node2|node3]"
        fi
    ;;
    clear )
        if [ "$2" = "node1" -o "$2" = "node2" -o "$2" = "node3" ];then
            read -p "确定要清除掉${2}的所有数据吗? [y|N]: " choose1
            if [ "$choose1" = "y" -o "$choose1" = "yes" -o "$choose1" = "Y" -o "$choose1" = "YES" ];then
                _clear "$2"
            else
                exit 1
            fi
        else
            echo "Usage:  $(basename $0) clear [node1|node2|node3]"
        fi
    ;;
    * )
        help_msg
    ;;
esac
