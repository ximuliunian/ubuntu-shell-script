#!/bin/bash

# 检查参数数量
if [ $# -ne 2 ]; then
    echo "用法: $0 <挂载目录> <监听端口>"
    echo "例子: $0 ~/apps/anythingllm 3001"
    echo "前置条件:"
    echo "  1. 具备 Docker 环境"
    echo "  2. 已拉取 anythingllm 镜像（docker pull mintplexlabs/anythingllm）"
    exit 1
fi

# 定义变量
MOUNT_DIR="$1"
HOST_PORT="$2"
CONTAINER_NAME="anythingllm"
IMAGE_NAME="mintplexlabs/anythingllm:master"

# 创建挂载目录结构
echo "正在创建挂载目录结构..."
mkdir -p "${MOUNT_DIR}/storage"
mkdir -p "${MOUNT_DIR}/logs"

# 清理已存在的容器
echo "正在清理已存在的容器..."
docker stop "${CONTAINER_NAME}" 2>/dev/null || true
docker rm "${CONTAINER_NAME}" 2>/dev/null || true

# 创建默认配置文件
echo "正在生成默认配置文件..."
cat <<EOF > "${MOUNT_DIR}/.env"
STORAGE_DIR=/app/server/storage
LOG_LEVEL=info
EOF

# 设置安全的目录权限
echo "正在设置目录权限..."
chmod -R 777 "${MOUNT_DIR}" "${MOUNT_DIR}/storage" "${MOUNT_DIR}/logs"
chown -R "$USER:$USER" "${MOUNT_DIR}"

# 运行容器
echo "正在启动 AnythingLLM 容器..."
docker run -d \
    --name "${CONTAINER_NAME}" \
    -p "${HOST_PORT}:3001" \
    --cap-add=SYS_ADMIN \
    --restart unless-stopped \
    -v "${MOUNT_DIR}/storage:/app/server/storage" \
    -v "${MOUNT_DIR}/.env:/app/server/.env" \
    -v "${MOUNT_DIR}/logs:/var/log/anythingllm" \
    -e STORAGE_DIR=/app/server/storage \
    -e STORAGE_DIR_HOST=${MOUNT_DIR}/storage \
    "${IMAGE_NAME}"

# 验证容器状态
if [ $? -eq 0 ]; then
    echo "✅ AnythingLLM 容器已成功启动"
    echo "   宿主机访问地址: http://localhost:${HOST_PORT}"
    echo "   数据存储路径: ${MOUNT_DIR}/storage"
    echo "   日志存储路径: ${MOUNT_DIR}/logs"
    echo "   配置文件路径: ${MOUNT_DIR}/.env"
    echo "   日志：docker logs -f ${CONTAINER_NAME}"
else
    echo "❌ 容器启动失败，请检查日志: docker logs ${CONTAINER_NAME}"
    exit 1
fi