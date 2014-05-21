#!/bin/bash
#Auto-Upgrade Script prototype
#traiano 21/05/2014
VERBOSE=1

#1. Basic Upgrade Sequence
#2. Build a new virtual disk
#3. Check Status of VM and either shut it down gracefully or return error
#4. Check Status of VM and detach program disk if shutdown complete
#5. Backup the old program disk to a folder
#6. Attach the new program disk to the VM
#7. Power up the VM
#8. Check if the VM powered up successfully
#9. Do a diagnostic health check to check if the VM upgraded properly
#10. Report success or failure
#11. Rollback automatically (attach the old disk)

function parse_args {
  source_path=$1
  auth_token=$2
  bverbose "(parse_args $source_path $auth_token) #parse and validate the script argument (upgrade source file, security token)"
}

function vm_check_state {
 bverbose "(vm_check_state) #check the current state of the VM"
}

function validate_upgrade_source {
 bverbose "(validate_upgrade_source) #check the upgrade sources are valid"
}

function attach_program_disk {
 bverbose "(attach_program_disk) #attach the newly built program disk to the vm"
}

function detach_program_disk {
 bverbose "(detach_program_disk) #detach the previous program disk from the VM" 
}

function create_program_disk {
 bverbose " (create_program_disk) #create a new program disk mount and add a filesystem, then copy the installation directory/sources over it"
}

function vm_powerup {
 bverbose " (vm_powerup) #power up the VM and monitor until done"
}

function vm_powerdown {
 bverbose " (vm_powerdown) #power down the VM monitor until done"
}

function poll_vm {
 bverbose " (poll_vm) #used by any functions to check the current vm state following any action"
}

function handle_error {
 bverbose " (handle_error) #do something sensible with errors or unexpected return values"
}

function debug {
 bverbose " (debug) #return verbose error messages to stdin"
}

function log_results {
 bverbose "(log_results) #log the results of every operation to the log"
}

function bverbose {
 msg=$1 
 caller=$0
 if [ $VERBOSE == 1 ]; then
  printf " $msg"
  echo ""
 fi
}

function exercise {
 #enumerate the functions in this auto-upgrade script
 if [ $VERBOSE == 1 ]; then
  parse_args "/upgrade" "xxxxxx"
  vm_check_state
  validate_upgrade_source
  attach_program_disk
  detach_program_disk
  create_program_disk
  vm_powerup
  vm_powerdown
  poll_vm
  handle_error
  debug
  log_results
  bverbose
 fi
}

#All the action happens below this line
exercise


