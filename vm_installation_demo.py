#!/usr/bin/python
#wrapper script around VBoxManage to demonstrate 
#Automated VM Appliance creation and installation 
#Using an "upgrade server" deployed alongside the 
#target appliance
#traiano@peplink.com
#NOTE: The O.S installation component is missing from this script 
#as it requires additional infrastructure (a preseed configuration and PXE repository
#for installing the guest OS in the VM. This may be added later.
#Tested on Mac OS X 10.9 with VirtualBox 4.3.10 
import time
import subprocess

#set a name for the vm here
vmname = "qasar"

#turn on debugging messages 
debug = 1 

#VBoxManager Command
VBM_CMD = "/usr/bin/VBoxManage"

#VBoxHeadless Command
VBH_CMD = "/usr/bin/VBoxHeadless"

def create_vm(vm_name):
 cmd = VBM_CMD + " createvm " + "--name " + vm_name + " --register"
 #output should be a UUID and a path to the virtual file. Something like:
 #UUID: d67746cd-cb27-46df-87e4-985b578c442e
 #Settings file: '/Users/traianow/VirtualBox VMs/neutrino/neutrino.vbox'
 result=runcommand(cmd)
 if(debug == 1):
  print "D > (Creating VM ... ): ", vm_name
  print "D > (cmd): ", result
 return result

def add_memory(vm_name, memory):
 cmd = VBM_CMD + " modifyvm "  + vm_name + " --memory " + str(memory) + " --acpi on " + " --boot1 dvd "
 result=runcommand(cmd)
 if(debug == 1):
  print "D > Adding Memory: ", memory
  print "D > (cmd): ", result
 return result

def add_bridged_nic(vm_name):
 cmd = VBM_CMD + " modifyvm " + vm_name + " --nic1 bridged" + " --bridgeadapter1" + " eth0"
 result=runcommand(cmd)
 if(debug == 1):
  print "D > Adding a Bridged NIC: ", vm_name
  print "D (cmd): ", result
 return result

def configure_mac(vm_name,mac_address):
 cmd = VBM_CMD + " modifyvm " + vm_name + " --macaddress1 " + mac_address
 result=runcommand(cmd)
 if(debug == 1):
  print "D > Configuring MAC Address to NIC ", mac_address
  print "D ( " + cmd + " ): " + result
 return result

def configure_os_type(vm_name,os_type):
 cmd = VBM_CMD + " modifyvm " + " " + vm_name + " --ostype " + os_type
 result=runcommand(cmd)
 if(debug == 1):
  print "D > Setting the O.S Type: ", os_type
  print "D > ( " + cmd + " ): " + result
 return result

def create_storage(vm_disk_filename,disk_size):
 cmd = VBM_CMD + " createhd " + " --filename " + vm_disk_filename + " --size " + disk_size
 result=runcommand(cmd)
 if(debug == 1):
  print "D ( Creating disk device ): " + vm_disk_filename 
  print "D ( " + cmd + " ): " + result
  result=filter_disk_uuid(result)
 disks[vm_disk_filename] = result
 return result

def filter_disk_uuid(sample_string):
 #quick and dirty extraction of the UUID
 #remove all whitespace
 sample_string.replace(" ","")
 #split on ":"
 parts = sample_string.split(":")
 #take the second element
 #split on "\"
 parts2 = parts[1].split("\\")
 result_string = parts2[0]
 if(debug == 1):
  print "D > Filtering the disk UUID string: ", result_string
 return result_string

def add_storage_controller(vm_name,controller_type):
 cmd = VBM_CMD + " storagectl " + vm_name + " --name " + "'IDE Controller' " + "--add " + controller_type 
 result=runcommand(cmd)
 if(debug == 1):
  print "D > Adding a Storage Controller: ", controller_type 
  print "D ( " + cmd + " ): " + result
 return result

def attach_disk_storage(vm_name,controller_name,disk_filename):
 (port, device) = register_ide_attachment(disk_filename)
 cmd = VBM_CMD + " storageattach " + vm_name +  " --storagectl " + controller_name + " --port " + port + " --device " + device + " --type hdd " + " --medium " + disk_filename
 print "CMD: ", cmd
 result=runcommand(cmd)
 if(debug == 1):
  print "D > Attaching storage to the controller: ", disk_filename, "Attaching to : ", controller_name 
  print "D > ( " + cmd + " ): " + result
 return result

def attach_install_iso(vm_name,controller_name,install_iso_name):
 cmd = VBM_CMD + " storageattach " + vm_name + " --storagectl " + controller_name + " --port 1 --device 0 --type dvddrive --medium " + install_iso_name
 result=runcommand(cmd)
 if(debug == 1):
  print "D > Attaching an Install ISO: ", install_iso_name
  print "D > ( " + cmd + " ): " + result
 return result

def detach_install_iso(vm_name):
 cmd = VBM_CMD + " modifyvm " + vm_name + " --dvd none"
 result=runcommand(cmd)
 if(debug == 1):
  print "D > De-taching the Install ISO: ", install_iso_name
  print "D ( " + cmd + " ): " + result
 return result

def start_os_installation(vm_name):
 cmd = VBH_CMD + " --startvm " + vm_name + "&"
 result=runcommand(cmd)
 if(debug == 1):
  print "D > Starting the OS Installation for ", vm_name
  print "D ( " + cmd + " ): " + result
 return result

def runcommand( command_string ):
 p = subprocess.Popen( command_string, stdout=subprocess.PIPE, shell=True)
 (output, err) = p.communicate()
 if(debug == 1):
  print "D > running VirtualBox Command:  ", command_string 
  print "D > CMD OUTPUT: ", output
 return output 

def poweroff_vm(vm_name):
 cmd = VBM_CMD + " controlvm " + vm_name + " poweroff"
 result=runcommand(cmd)
 if(debug == 1):
  print "D > Powering off the VM: ", vm_name
  print "D > ( " + cmd + " ): " + result
 return result

def remove_install_media(vm_name):
 cmd = VBM_CMD + " modifyvm " + vm_name + " --dvd none"
 result=runcommand(cmd)
 if(debug == 1):
  print "D > Removing installation media: ", vm_name
  print "D ( " + cmd + " ): " + result
 return result

def register_ide_attachment(disk_filename):
 #we have to make sure to attach
 #virtual disks to the correct ide
 #ports, taking into account that only 2 disks
 #can be attached to a given ide port at a time
 #and there are 2 ports for each ide controller
 #giving us a total of 4 disks per controller
 #we keep track of the following mapping
 #with each device that is attached to the
 #Vms controller:
 #0,0 : disk 1, device 1 on port 0 
 #0,1 : disk 2, device 2 on port 0
 #1,0 : disk 3, device 0 on port 1
 #1,1 : disk 4, device 1 on port 1
 for key in ide_ports:
  print "K: ", key, " V: ",ide_ports[key]
  if(ide_ports[key] == "empty" ):
   result = key
   ide_ports[key] = disk_filename
   parts = list(result)
   port = parts[0]
   device = parts[1]
   print "Port: ", port, "Device id: ", device, "Now Contains: ", ide_ports[key]
   break
 return port, device 

def environment( string ):
 #test function to check the python and virtualbox environment
 print "Checking our environment: ", string 
 return string

def destroy_vm_utterly(vm_name):
 cmd = VBM_CMD + " unregistervm " + vm_name + " --delete"
 result=runcommand(cmd)
 if(debug == 1):
  print "D > Hanging around for 10 seconds before cleaning everything up ..."
  time.sleep(10)
  print "D ( " + cmd + " ): " + result
 return result

#All the action happens below here:

#mapping table to keep track of occupied
#ide controller ports
ide_ports = {
 "00":"empty",
 "01":"empty",
 "10":"empty",
 "11":"empty"
}

#VM Settings
#Configure the VM with the following settings:
#Note that we could take these settings from another source, e.g
#JSON configuration file, DB table etc ...
vm_root_disk_index = "root"
vm_data_disk_index = "data"
vm_etc_disk_index = "etc"
vm_name = vmname
memory = 256
mac_address = "080027DB67DB" 
os_type = "Debian"
vm_vbox_settings_file = "/Users/traianow/VirtualBox VMs/neutrino/vm_name" + ".vbox"
vm_root_disk_filename = "/Users/traianow/VMdisks/" + vm_name + vm_root_disk_index + ".vdi"
vm_data_disk_filename = "/Users/traianow/VMdisks/" + vm_name + vm_data_disk_index + ".vdi"
vm_etc_disk_filename = "/Users/traianow/VMdisks/" + vm_name + vm_etc_disk_index + ".vdi"
vm_disks = [vm_data_disk_filename,vm_etc_disk_filename]
disk_size = "10000"
controller_type = "ide"
controller_name = "'" + "IDE Controller" + "'"
install_iso_name = "/Users/traianow/Isos/ITIL-DSL/debian/debian-6.0.5-amd64-DVD-1.iso"

#disk name to uuid mappings
#the system returns uuid on creation
#of new disk. We limit  to 3 virtual
#disks in this hypothetical case 
disks = {
 vm_root_disk_filename:"uuid1",
 vm_data_disk_filename:"uuid2",
 vm_etc_disk_filename:"uuid3"
}

create_vm(vm_name)
time.sleep(4)

add_memory(vm_name, memory)
time.sleep(2)

add_bridged_nic(vm_name)
time.sleep(2)

configure_mac(vm_name,mac_address)
time.sleep(2)

configure_os_type(vm_name,os_type)
time.sleep(2)

create_storage(vm_root_disk_filename,disk_size)
time.sleep(2)

#iterate through the list of additional
#virtual disks and 
#create the data and etc disks
for disk in vm_disks:
 time.sleep(2)
 create_storage(disk,disk_size)

add_storage_controller(vm_name,controller_type)
time.sleep(2)

attach_disk_storage(vm_name,controller_name,vm_root_disk_filename)
time.sleep(2)

#iterate through the list of additional
#virtual disks and attach them to the primary ide
for disk in vm_disks:
 attach_disk_storage(vm_name,controller_name,disk)
 time.sleep(2)

poweroff_vm(vm_name)
time.sleep(4)

attach_install_iso(vm_name,controller_name,install_iso_name)
time.sleep(2)

start_os_installation(vm_name)
time.sleep(4)

poweroff_vm(vm_name)
time.sleep(4)

remove_install_media(vm_name)
time.sleep(2)

output = destroy_vm_utterly(vm_name)
print "Output from destroy VM (", vmname, " ): ", output
