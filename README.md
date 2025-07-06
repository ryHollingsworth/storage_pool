# USB SSD Pool Setup Script (with mergerfs)

This script automates the process of preparing and pooling multiple USB SSDs into a single unified storage mount using [`mergerfs`](https://github.com/trapexit/mergerfs). 

Potential uses cases for pooled drives: 

- Raspberry Pi NAS setups
- NextcloudPi servers
- BorgBackup storage nodes
- Home cloud file servers

---

## ⚠️ WARNING

🚨 This script will format all detected external drives (`/dev/sd[b-z]`). **Do not run this script with any other critical drives connected.** You will lose all data on those drives.

---

## 🔧 What It Does

1. Detects all `/dev/sd[b-z]` drives
2. Formats them as `ext4` with labels like `ssd1`, `ssd2`, etc.
3. Mounts each drive at `/mnt/ssdX`
4. Installs `mergerfs` and creates a unified mount at `/mnt/merged`
5. Sets ownership of `/mnt/merged` to your chosen user
6. Optionally adds entries to `/etc/fstab` for persistent mounting

---

## ✅ Requirements

- Debian-based Linux (Raspberry Pi OS, Ubuntu, Armbian, etc.)
- `sudo` privileges
- A powered USB hub or PCB HAT (for multiple SSDs) 
- Only the target USB drives connected during setup

---

## 🚀 Usage

### 1. Make script executable:
```bash
chmod +x setup_storage_pool.sh
