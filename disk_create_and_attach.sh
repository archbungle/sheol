#!/bin/bash
#functions to create a virtual disk
#unit test 1
XE="/opt/xensource/bin/xe"
VM_NAME="c65t000"
SR_UUID=""
DISK_SIZE="5GiB"
VM_UUID=""
VBD_UUID=""
NEXT_VBD_POSN=10
LOCAL_STORAGE_NLABEL="Local Storage 2"

function create_program_disk {
 find_local_sr 
 unixtime
 printf "SR UUID: $SR_UUID\n"
 printf "TIMESTAMP: $TIMESTAMP\n"
 #find the VM UUID corresponding to the VM we want to upgrade:
 find_vm_uuid $VM_NAME
 DISK_NAME_LABEL="pgm_disk_$TIMESTAMP"
 VDI_UUID=`xe vdi-create sr-uuid=$SR_UUID name-label=$DISK_NAME_LABEL name-description="program disk" type=user virtual-size="$DISK_SIZE"`
 printf "D (new virtual disk ID): $VDI_UUID\n"
 $XE vdi-list name-label=$DISK_NAME_LABEL
 #Create the virtual block device and attach it to the VM
 create_vbd $VDI_UUID $VM_UUID
}

function find_local_sr {
 #find the uuid of the local storage repository
 SR_NAME_LABEL="$LOCAL_STORAGE_NLABEL"
 printf "Searching for SR: \"$SR_NAME_LABEL\"\n"
 SR_UUID=`$XE sr-list name-label="$SR_NAME_LABEL" | grep uuid | cut -d ':' -f 2| sed -s "s/^\s//g"`
 printf "D : $SR_UUID\n"
}

function unixtime {
 TIMESTAMP=`date +"%s"`
}

function create_vbd {
 VDI_UUID=$1
 VM_UUID=$2
 #Get the next available position for the virtual block device attachment to the VM:
 get_next_vbd_position $VM_UUID
 VBD_UUID=`$XE vbd-create vm-uuid=$VM_UUID device=$NEXT_VBD_POSN vdi-uuid=$VDI_UUID bootable=false mode=RW type=Disk`
 printf "D: $XE vbd-create vm-uuid=$VM_UUID device=$NEXT_VBD_POSN vdi-uuid=$VDI_UUID bootable=false mode=RW type=Disk \n"
 printf "D (virtual block device uuid): $VBD_UUID \n"
}

function get_next_vbd_position {
 #get the next available virtual block device
 #attachement ID/position on the VM
 VM_UUID=$1
NEXT_VBD_POSN=`$XE vm-param-list uuid=$VM_UUID | grep allowed-VBD-devices| cut -d ":" -f 2| cut -d ";" -f 1| sed -s "s/^\s//g"`
 printf "D (get_next_vbd_position): $NEXT_VBD_POSN\n"
}

function find_vm_uuid {
 #find the VM uuid given it's name-label (i.e, it's "name")
 VM_NAME_LABEL=$1
 VM_UUID=`xe vm-list name-label=$VM_NAME_LABEL params=uuid | cut -d ":" -f 2| sed -s "s/^\s//g"`
 printf "D (find_vm_uuid): $VM_UUID"
}

function attach_program_disk {
 #attaching ("plug in") the newly created virtual block device to the VM
 VBD_UUID=$1
 RESULT=`xe vbd-plug uuid=$VBD_UUID`
 printf "D (attach_program_disk): xe vbd-plug uuid=$VBD_UUID ($RESULT)\n"
 return $RESULT
}

#All the action happens below here:

create_program_disk
attach_program_disk $VBD_UUID


