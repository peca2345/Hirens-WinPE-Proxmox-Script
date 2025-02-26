#!/bin/bash

# Configuration variables
ISO_URL="https://www.hirensbootcd.org/files/HBCD_PE_x64.iso"
ISO_NAME="HBCD_PE_x64.iso"
STORAGE_NAME="local"  # Storage for ISO (modify according to your setup)
VM_ID="9000"  # ID for the new VM (change as needed)
VM_NAME="HirensBootCD"
VM_MEMORY="2048"  # Memory in MB
VM_CORES="2"  # Number of CPU cores
VM_DISK_SIZE="8G"  # Disk size
VM_DISK_STORAGE="local-lvm"  # Storage for VM disk (modify according to your setup)
VM_NETWORK="vmbr0"  # Network bridge (modify according to your setup)

# Check if script is running as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root"
    exit 1
fi

# Check if ISO already exists in storage
if pvesm list $STORAGE_NAME | grep -q "$ISO_NAME"; then
    echo "ISO already exists in storage, skipping download"
else
    # Download the ISO file
    echo "Downloading Hiren's BootCD PE ISO..."
    wget -O /tmp/$ISO_NAME $ISO_URL
    
    # Upload ISO to Proxmox storage
    echo "Uploading ISO to Proxmox storage..."
    pvesm upload $STORAGE_NAME /tmp/$ISO_NAME --content iso
    
    # Remove temporary file
    rm /tmp/$ISO_NAME
fi

# Check if VM with the given ID already exists
if qm status $VM_ID &>/dev/null; then
    echo "VM with ID $VM_ID already exists. Choose another ID or remove the existing VM."
    exit 1
fi

# Create a new virtual machine
echo "Creating new virtual machine..."
qm create $VM_ID --name $VM_NAME --memory $VM_MEMORY --cores $VM_CORES --net0 virtio,bridge=$VM_NETWORK --bios ovmf
qm set $VM_ID --scsihw virtio-scsi-pci --scsi0 $VM_DISK_STORAGE:$VM_DISK_SIZE
qm set $VM_ID --boot c --bootdisk scsi0
qm set $VM_ID --ide2 $STORAGE_NAME:iso/$ISO_NAME,media=cdrom
qm set $VM_ID --boot order=ide2
qm set $VM_ID --ostype win10

echo "Hiren's BootCD virtual machine has been created with ID $VM_ID"
echo "To start the VM, use: qm start $VM_ID"
