#!/bin/bash
#VM Auto upgrade script
#traiano@peplink.com
#helper script to migrate important
#program files onto a detachable virtual disk
#

#Migration Algorithm:
#-------------------
#1. create a filesystem on /dev/xvdb
#2. sync/copy /usr/ on to /dev/xvdb
#3. edit /etc/fstab: mount /dev/xvdb on /usr/     
#4. Remove everything under /usr/ leaving only the mount point
#5. mount -a to mount /dev/xvdb onto /usr/
#6. reboot

#Tunable variables here:
MIGRATE_DIR="/usr/"
MIGRATE_TARGET_DEVICE="/dev/xvdb "
ETC_FSTAB="/tmp/fstab "
REBOOT_CMD="/sbin/reboot "
SYNCFS_CMD="/usr/bin/rsync -avx "
MKFS_CMD="/sbin/mkfs.xfs "
MOUNT_CMD="/bin/mount "
MOUNT_DIR="/mnt"
FILE_CMD="/usr/bin/file "
HAZ_DEVICE=0

function check_device {
 #check if the device is there at all
 #because we can't just go along on faith
 printf "Checking if our block device exists: $FILE_CMD $MIGRATE_TARGET_DEVICE \n"
 RESULT=`$FILE_CMD $MIGRATE_TARGET_DEVICE |  grep "block special"| wc -l`
 printf "RESULT (check_device): $RESULT \n"
 if [ $RESULT == 0 ];then
  printf "NO BLOCK DEVICE :-( : $RESULT \n"
 else
  printf "Found block device, not quitting: $RESULT \n"
  HAZ_DEVICE=$RESULT
 fi
}

function make_filesystem {
 #make an (default xfs) filesystem on the target device
 MIGRATE_TARGET_DEVICE=$1 
 MKFS_CMD=$2
 printf "Running: $MKFS_CMD $MIGRATE_TARGET_DEVICE"
 RESULT=`$MKFS_CMD $MIGRATE_TARGET_DEVICE`
 printf "RESULT (make filesystem): $RESULT \n"
}

function temp_mount {
 #temporary mount the device to copy /usr/*
 #to it
 printf "Running: $MOUNT_CMD $MIGRATE_TARGET_DEVICE $MOUNT_DIR"
 RESULT=`$MOUNT_CMD $MIGRATE_TARGET_DEVICE $MOUNT_DIR`
 printf "RESULT (temporary mount the new device): $RESULT \n"
}

function sync_fs {
 #Synchronise the contents of the source directory
 #with the target device mounted on $MOUNT_DIR
 printf "Running: $SYNCFS_CMD $SOURCE_DIR $MOUNT_DIR"
 RESULT=`$SYNCFS_CMD $SOURCE_DIR $MOUNT_DIR`
 printf "RESULT (sync_fs): $RESULT\n"
}

function update_fstab {
 #update the /etc/fstab after synching the directories onto the new device
 FSTAB_LINE="$MIGRATE_TARGET_DEVICE                        xfs    defaults        1 2"
 printf "Touching: $ETC_FSTAB \n"
 RESULT=`touch $ETC_FSTAB`
 printf "RESULT: $RESULT \n"
 printf "Updating $ETC_FSTAB with: $FSTAB_LINE"
 RESULT=`echo $FSTAB_LINE >> $ETC_FSTAB`
 printf "RESULT: $RESULT \n"
}

function clear_source_directory {
 #lcear the source directory, since it 
 #has been migrated to a separate device 
 printf "Simulating removal of the source directory: \n"
 if [ -e $SOURCE_DIR ];then
  CMD="rm -rf $SOURCE_DIR"
  printf "D (clearing source directory): $CMD \n"
 else
  printf "Source directory does not exist, not removing anything! $SOURCE_DIR \n"
 fi
}

function unmount_device {
 #unmounted the newly created device
 #after synching the program files directories
 printf "Unmounting the new program drive \n"
 printf "$UMOUNT $MIGRATE_TARGET_DEVICE \n"
 RESULT=`$UMOUNT $MIGRATE_TARGET_DEVICE`
 print "RESULT: $RESULT \n"
}

function mount_new_usr {
 #mount the newly migrated directory on the correct
 #mount point
 printf "Mount newly migrated directory \n "
}

function reboot_vm {
 #reboot the vm to test if the critical directories 
 #are correctly mounted
 printf "Rebooting ...\n "
}

function fflush {
 #flush, like mommy taught us to ..
 printf "Flushing FS buffers to disk ...\n"
 sync;sync;sync;sync
}

#All the action ahppens below this line:

#check for the device:
check_device
if [ $HAZ_DEVICE == 1 ];then
 printf "device exists ... continuing"
 check_device
 make_filesystem
 temp_mount
 sync_fs
 unmount_device
 fflush
fi

