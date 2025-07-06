#!/bin/bash

set -e

MOUNT_BASE="/mnt"
MERGE_DIR="/mnt/merged"

read -rp "[INPUT] Enter the username that should own the storage (default: $(logname)): " GENERIC_USER
GENERIC_USER=${GENERIC_USER:-$(logname)}


echo "[INFO] Identifying SSDs (excluding boot drive)..."
DRIVES=$(lsblk -dpno NAME | grep -E '^/dev/sd[b-z]$')

if [[ -z "$DRIVES" ]]; then
  echo "[ERROR] No external drives detected. Exiting."
  exit 1
fi

echo "[INFO] The following drives will be formatted and used:"
echo "$DRIVES"
read -rp "[PROMPT] Proceed? This will FORMAT all listed drives. Type YES to continue: " CONFIRM

if [[ "$CONFIRM" != "YES" ]]; then
  echo "Aborted."
  exit 1
fi

i=1
for DRIVE in $DRIVES; do
  LABEL="ssd$i"
  MOUNT_POINT="${MOUNT_BASE}/${LABEL}"

  echo "[INFO] Formatting $DRIVE as ext4 with label $LABEL..."
  sudo mkfs.ext4 -F -L "$LABEL" "$DRIVE"

  echo "[INFO] Creating mount point $MOUNT_POINT..."
  sudo mkdir -p "$MOUNT_POINT"
  sudo mount "$DRIVE" "$MOUNT_POINT"

  i=$((i+1))
done

echo "[INFO] Installing mergerfs if not already present..."
sudo apt update && sudo apt install -y mergerfs

echo "[INFO] Creating unified mount point at $MERGE_DIR..."
sudo mkdir -p "$MERGE_DIR"

echo "[INFO] Mounting unified view using mergerfs..."
sudo mergerfs "${MOUNT_BASE}/ssd*" "$MERGE_DIR"

echo "[INFO] Setting ownership to $GENERIC_USER..."
sudo chown -R "$GENERIC_USER:$GENERIC_USER" "$MERGE_DIR"

echo "[INFO] Current disk usage:"
df -h | grep '/mnt/'

read -rp "[OPTIONAL] Add drives and mergerfs to /etc/fstab for auto-mount? (yes/no): " DO_FSTAB

if [[ "$DO_FSTAB" == "yes" ]]; then
  echo "[INFO] Backing up fstab to /etc/fstab.bak"
  sudo cp /etc/fstab /etc/fstab.bak

  echo "[INFO] Writing fstab entries..."

  for DRIVE in $DRIVES; do
    UUID=$(blkid -s UUID -o value "$DRIVE")
    LABEL=$(blkid -s LABEL -o value "$DRIVE")
    echo "UUID=$UUID ${MOUNT_BASE}/$LABEL ext4 defaults 0 0" | sudo tee -a /etc/fstab
  done

  echo "${MOUNT_BASE}/ssd* ${MERGE_DIR} fuse.mergerfs defaults,allow_other,use_ino,category.create=mfs 0 0" | sudo tee -a /etc/fstab

  echo "[INFO] Testing fstab mounts..."
  sudo mount -a
fi

echo "[DONE] All drives merged and mounted at $MERGE_DIR"
