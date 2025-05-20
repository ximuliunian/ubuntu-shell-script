#!/bin/bash

# 检查参数数量
if [ $# -ne 2 ]; then
    echo "用法: $0 <挂载目录> <监听端口>"
    echo "例子: $0 ~/apps/mongo 27017"
    exit 1
fi

# 定义变量
MOUNT_DIR=$1
HOST_PORT=$2

# 数据库账密
MONGO_INITDB_ROOT_USERNAME=root
MONGO_INITDB_ROOT_PASSWORD=root

# 创建目录结构
echo "正在创建挂载目录..."
mkdir -p "${MOUNT_DIR}/db"
mkdir -p "${MOUNT_DIR}/log"

# 清理已存在的MongoDB容器
echo "正在清理已存在的MongoDB容器..."
docker stop mongo 2>/dev/null || true
docker rm mongo 2>/dev/null || true

# 创建临时容器以生成初始数据
echo "正在创建临时容器以生成MongoDB数据..."
docker run --name temp-mongo -d \
    --privileged=true \
    -e "MONGO_INITDB_ROOT_USERNAME=${MONGO_INITDB_ROOT_USERNAME}" \
    -e "MONGO_INITDB_ROOT_PASSWORD=${MONGO_INITDB_ROOT_PASSWORD}" \
    mongo

# 等待MongoDB初始化完成
echo "等待MongoDB初始化..."
until docker logs temp-mongo 2>&1 | grep -q 'waiting for connections on port 27017'; do
    sleep 2
done

# 停止临时容器
echo "停止临时容器..."
docker stop temp-mongo

# 拷贝数据到宿主机
echo "正在复制MongoDB数据..."
docker cp temp-mongo:/data/db "${MOUNT_DIR}/db"

# 设置目录权限
echo "正在设置目录权限..."
chmod -R 777 "${MOUNT_DIR}/db" "${MOUNT_DIR}/log"

# 删除临时容器
echo "正在删除临时容器..."
docker rm -f temp-mongo

# 启动正式容器
echo "正在启动MongoDB容器..."
docker run --restart=always --name mongo \
    -p "${HOST_PORT}:27017" \
    -e TZ=Asia/Shanghai \
    -v "${MOUNT_DIR}/db:/data/db" \
    -v "${MOUNT_DIR}/log:/data/log" \
    --privileged=true \
    -e "MONGO_INITDB_ROOT_USERNAME=${MONGO_INITDB_ROOT_USERNAME}" \
    -e "MONGO_INITDB_ROOT_PASSWORD=${MONGO_INITDB_ROOT_PASSWORD}" \
    -d mongo

echo "✅ MongoDB容器已启动"
echo "   宿主机访问端口: ${HOST_PORT}"
echo "   挂载目录: ${MOUNT_DIR}"
echo "   用户名: ${MONGO_INITDB_ROOT_USERNAME}"
echo "   密码: ${MONGO_INITDB_ROOT_PASSWORD}"