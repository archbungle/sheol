#!/bin/bash
#detach /dev/xvdb (which we assume to be the program disk)
#from a running VM
#This results in the destruction of the disk
VM_NAME_LABEL="ic2-install-test-vm-001"
VBD_NAME="xvdc"
VM_UUID=""
XE="xe"
VM_STATE=1

function detach_program_disk {
 find_vm_uuid $VM_NAME_LABEL
 list_vm_disks $VM_UUID
 vm_state_query $VM_UUID
 if [ $VM_STATE == 1 ];then
  shutdown_vm $VM_UUID
 fi
 while [ $VM_STATE == 1 ]
 do
  vm_state_query $VM_UUID
  printf "D: Waiting for $VM_NAME_LABEL to power off  ($VM_STATE)...\n"
  sleep 2
 done
 find_program_disk_uuid
 unplug_program_disk $VBD_UUID
 destroy_program_disk $VBD_UUID 
 list_vm_disks $VM_UUID
 powerup_vm $VM_UUID
 while [ $VM_STATE == 0 ]
 do
  vm_state_query $VM_UUID
  printf "D: Waiting for $VM_NAME_LABEL to power up ...\n"
 done
}

function vm_state_query {
 VM_UUID=$1
 VM_STATE=`$XE vm-list uuid=$VM_UUID params=power-state| cut -d ":" -f  2 | sed -s "s/^\s//g"| grep "[a-zA-Z0-9]"| grep "running"|wc -l`
 #echo "\"$XE vm-list uuid=$VM_UUID params=power-state| cut -d \":\" -f  2 | sed -s \"s/^\s//g\"| grep \"[a-zA-Z0-9]"| grep "running"|wc -l"
 if [[ $VM_STATE == 1 || $VM_STATE == 0 ]]; then
  printf "D: VM_STATE: $VM_STATE\n"
 else
  printf "D: Invalid state:e $VM_STATE\n"
 fi
}

function find_program_disk_uuid {
 find_vm_uuid $VM_NAME_LABEL
 VBD_UUID=`$XE vbd-list vm-uuid=$VM_UUID device=$VBD_NAME| grep "^uuid"| cut -d ":" -f 2| sed -s "s/\s//g"`
 printf "D: VBD_UUID : $VBD_UUID \n"
}

function unplug_program_disk {
 VBD_UUID=$1
 UNPLUG_RESULT=`$XE vbd-unplug uuid=$VBD_UUID`
 printf "D: UNPLUG_RESULT: $UNPLUG_RESULT \n"
}

function destroy_program_disk {
 VBD_UUID=$1
 DESTROY_RESULT=`$XE vbd-destroy uuid=$VBD_UUID`
 printf "DESTROY_RESULT: $DESTROY_RESULT \n"
}

function shutdown_vm {
 VM_UUID=$1
 SHUTDOWN_RESULT=`$XE vm-shutdown uuid=$VM_UUID`
 printf "D: SHUTDOWN_RESULT: $SHUTDOWN_RESULT \n"
}

function powerup_vm {
 VM_UUID=$1
 printf "D: Powering up VM $VM_UUID \n"
 POWERUP_RESULT=`$XE  vm-start uuid=$VM_UUID`
 printf "D: POWER UP RESULT: $POWERUP_RESULT \n"
}

function list_vm_disks {
  VM_UUID=$1
  printf "Listing disk devices currently attached to $VM_NAME_LABEL\n"
  VM_DISKS=`$XE vbd-list vm-uuid=$VM_UUID params=device`
}

function find_vm_uuid {
 #find the VM uuid given it's name-label (i.e, it's "name")
 VM_NAME_LABEL=$1
 VM_UUID=`xe vm-list name-label=$VM_NAME_LABEL params=uuid | cut -d ":" -f 2| sed -s "s/^\s//g"`
 printf "D (find_vm_uuid): $VM_UUID"
}

#All the action happens below here:

detach_program_disk


