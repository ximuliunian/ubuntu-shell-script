docker pull mintplexlabs/anythingllm:master

export STORAGE_LOCATION="$HOME/apps/anythingllm" && \
mkdir -p $STORAGE_LOCATION && \
touch "$STORAGE_LOCATION/.env" && \
docker run -d -p 21650:3001 \
--cap-add SYS_ADMIN \
--privileged=true \
--restart unless-stopped \
-v ${STORAGE_LOCATION}:/app/server/storage \
-v ${STORAGE_LOCATION}/.env:/app/server/.env \
-e STORAGE_DIR="/app/server/storage" \
mintplexlabs/anythingllm:master

chmod -R 777 $HOME/apps/anythingllm
