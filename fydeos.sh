#!/bin/bash

# FydeOS Installation Script
# Downloads, extracts, and installs FydeOS into a virtual disk image.

set -e

# Variables
FYDEOS_VERSION="19.0"
FYDEOS_URL="https://download.fydeos.io/v19.0/FydeOS_for_PC_iris_v19.0-io-stable.img.xz"
DISK_IMAGE="fydeos.img"
DISK_SIZE="16G" # Minimum size for FydeOS
GRUB_ENTRY="FydeOS"

usage() {
    echo "Usage: $0 -dst <disk image path> [-s <disk size>]"
    echo "   -dst, --destination: Path to the virtual disk image (e.g., /path/to/fydeos.img)"
    echo "   -s, --size: Size of the disk image (e.g., 16G, default: ${DISK_SIZE})"
    exit 1
}

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -dst|--destination) DISK_IMAGE="$2"; shift ;;
        -s|--size) DISK_SIZE="$2"; shift ;;
        *) usage ;;
    esac
    shift
done

if [[ -z "$DISK_IMAGE" ]]; then
    echo "Error: Destination disk image not specified."
    usage
fi

echo "Starting FydeOS installation..."
echo "Disk Image: ${DISK_IMAGE}"
echo "Disk Size: ${DISK_SIZE}"

# Step 1: Download FydeOS image
if [[ ! -f "fydeos.img.xz" ]]; then
    echo "Downloading FydeOS ${FYDEOS_VERSION}..."
    curl -L -o fydeos.img.xz "${FYDEOS_URL}"
else
    echo "FydeOS image already downloaded."
fi

# Step 2: Create a virtual disk image
if [[ ! -f "${DISK_IMAGE}" ]]; then
    echo "Creating virtual disk image (${DISK_IMAGE}) of size ${DISK_SIZE}..."
    truncate -s "${DISK_SIZE}" "${DISK_IMAGE}"
else
    echo "Disk image ${DISK_IMAGE} already exists."
fi

# Step 3: Extract FydeOS image to the virtual disk
echo "Extracting FydeOS image..."
xzcat fydeos.img.xz | dd of="${DISK_IMAGE}" bs=4M status=progress conv=sparse

# Step 4: Add FydeOS to GRUB
echo "Configuring GRUB entry for FydeOS..."
GRUB_CFG="/boot/grub/grub.cfg"

if [[ ! -d "/boot/grub" ]]; then
    echo "Error: GRUB is not installed or /boot/grub directory is missing."
    exit 1
fi

cat << EOF | sudo tee -a ${GRUB_CFG}
menuentry "${GRUB_ENTRY}" {
    set root='hd0,msdos1'
    linux /vmlinuz quiet root=/dev/sda3
    initrd /initrd.img
}
EOF

echo "Installation completed. Reboot and select FydeOS from GRUB to boot."

