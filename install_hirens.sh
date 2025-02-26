#!/usr/bin/env bash

# Copyright (c) 2025
# License: MIT
# Hiren's BootCD VM Setup Script for Proxmox

APP="Hiren's BootCD PE"
VM_ID=$(pvesh get /cluster/nextid)
VM_NAME="HirensBootCD"
ISO_URL="https://www.hirensbootcd.org/files/HBCD_PE_x64.iso"
ISO_NAME="HBCD_PE_x64.iso"
STORAGE_NAME="local"
VM_MEMORY="2048"
VM_CORES="2"
VM_DISK_SIZE="8G"
VM_DISK_STORAGE="local-lvm"
VM_NETWORK="vmbr0"

# Print header
echo -e "\e[1;34m$APP VM Setup\e[0m"
echo -e "\e[32mCreating a new VM with Hiren's BootCD PE\e[0m"

# Check if script is running as root
if [ "$(id -u)" -ne 0 ]; then
    echo -e "\e[31mThis script must be run as root\e[0m"
    exit 1
fi

# Check if ISO already exists in storage
if pvesm list $STORAGE_NAME | grep -q "$ISO_NAME"; then
    echo -e "\e[33mISO already exists in storage, skipping download\e[0m"
else
    # Download the ISO file
    echo -e "\e[32mDownloading Hiren's BootCD PE ISO...\e[0m"
    wget -q --show-progress -O /tmp/$ISO_NAME $ISO_URL
    
    # Upload ISO to Proxmox storage
    echo -e "\e[32mUploading ISO to Proxmox storage...\e[0m"
    pvesm upload $STORAGE_NAME /tmp/$ISO_NAME --content iso
    
    # Remove temporary file
    rm /tmp/$ISO_NAME
fi

# Create a new virtual machine
echo -e "\e[32mCreating new virtual machine with ID $VM_ID...\e[0m"
qm create $VM_ID --name $VM_NAME --memory $VM_MEMORY --cores $VM_CORES --net0 virtio,bridge=$VM_NETWORK --bios ovmf
qm set $VM_ID --scsihw virtio-scsi-pci --scsi0 $VM_DISK_STORAGE:$VM_DISK_SIZE
qm set $VM_ID --boot c --bootdisk scsi0
qm set $VM_ID --ide2 $STORAGE_NAME:iso/$ISO_NAME,media=cdrom
qm set $VM_ID --boot order=ide2
qm set $VM_ID --ostype win10

echo -e "\e[1;32m$APP virtual machine has been created with ID $VM_ID\e[0m"
echo -e "\e[33mTo start the VM, use: qm start $VM_ID\e[0m"
echo -e "\e[33mOr start it from the Proxmox web interface\e[0m"
