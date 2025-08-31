#!/bin/bash
set -euo pipefail

# Get from env or fail with default
: "${PROJECT:?}"
: "${REPO:?}"
: "${BUILD:?}"
: "${DOCKER:?}"
: "${IMAGE_DIR:?}"
: "${LOG:?}"

VERSION_FILE="$BUILD/VERSION"
COMPOSE="$DOCKER/docker-compose.yml"
CONTAINER_NAME="$PROJECT"

NEW_VERSION=$(cat "$BUILD/VERSION")

if [ -f "$DOCKER/VERSION" ]; then
  CURRENT_VERSION=$(cat "$DOCKER/VERSION")
else
  CURRENT_VERSION="0.0.0"
fi

IMAGE_TAG="$PROJECT:$NEW_VERSION"

if [ "$NEW_VERSION" == "$CURRENT_VERSION" ]; then
  echo "[$(date)] Version unchanged: [$NEW_VERSION], skipping deploy." | tee -a "$LOG"
  exit 0
fi

IMAGE_PATH="$IMAGE_DIR/$PROJECT-$NEW_VERSION.tar"

echo "[$(date)] Detected version change: [$CURRENT_VERSION] != [$NEW_VERSION]" | tee -a "$LOG"
echo "[$(date)] Checking if image exists: [$IMAGE_PATH]" | tee -a "$LOG"

if [ -f "$IMAGE_PATH" ]; then
  echo "[$(date)] Image already exists on disk, aborting." | tee -a "$LOG"
  exit 1
fi

cd "$BUILD"

echo "[$(date)] Building new image: $IMAGE_TAG" | tee -a "$LOG"
docker build --build-arg VERSION="$NEW_VERSION" -t "$IMAGE_TAG" . 2>&1 | tee -a "$LOG"

echo "[$(date)] Saving image to disk." | tee -a "$LOG"
docker save "$IMAGE_TAG" -o "$IMAGE_PATH" 2>&1 | tee -a "$LOG"

cd "$DOCKER"

PROJECT_GREP="^$PROJECT$"

if docker ps -a --format '{{.Names}}' | grep -q "$PROJECT_GREP"; then
  echo "[$(date)] Container exists. Stopping and removing old container" | tee -a "$LOG"
  docker compose -f "$COMPOSE" down 2>&1 | tee -a "$LOG"
else
  echo "[$(date)] No existing container found. Skipping stop step." | tee -a "$LOG"
fi

echo "[$(date)] Updating latest" | tee -a "$LOG"
docker tag "$IMAGE_TAG" "$PROJECT:latest"

echo "[$(date)] Update docker-compose.yml to latest version." | tee -a "$LOG"
cp "$BUILD/docker-compose.yml" "$COMPOSE"

echo "[$(date)] Starting new container" | tee -a "$LOG"
docker compose -f "$COMPOSE" up -d 2>&1 | tee -a "$LOG"

echo "[$(date)] Updating version." | tee -a "$LOG"
cp "$BUILD/VERSION" "$DOCKER/VERSION"

echo "[$(date)] Deploy complete." | tee -a "$LOG"
