#Automated deployment  of CentOS6.5 VMs on XenServer 6.5
#Cobbled together from sources all around the net
#Adjust the VM name
#below:
VMNAME="c65t010";
echo "VMNAME: $VMNAME"

TEMPLATENAME=CentOS6.5;
echo "TEMPLATENAME: $TEMPLATENAME"

NETNAME="Pool-wide network associated with eth0";
echo "NETNAME: $NETNAME"

#Your CentOS source mirror
MIRROR="http://10.0.0.5/repos/centos/centos65/";
echo "MIRROR: $MIRROR"

#Optionally, you may host your kickstart file anywhere 
#you'd like:
KICKFILE="http://10.0.0.5/kickstart.cfg";
echo "KICKFILE: $KICKFILE"

VMUUID=`xe vm-list name-label=$VMNAME params=uuid --minimal`;
echo "VMNAME: $VMNAME"

NETUUID=`xe network-list name-label="$NETNAME" params=uuid --minimal`;
echo "NETUUID: $NETUUID"

TEMPLATEUUID=`xe template-list name-label=$TEMPLATENAME params=uuid --minimal`;
echo "TEMPLATEUUID: $TEMPLATEUUID"

TEMPLATESOURCE=`xe template-list name-label=CentOS\ 6\ \(64-bit\) params=uuid --minimal`;
echo "TEMPLATESOURCE: $TEMPLATESOURCE"

SR=`mount |grep sr-mount |cut -d' ' -f3`; 
echo "SR: $SR"

if [ "$VMUUID" != "" ]; then 
 echo "VM exists previously: $VMUUID .. removing ..."
 xe vm-uninstall uuid=$VMUUID --force;
fi; 

if [ "$TEMPLATEUUID" != "" ]; then 
 echo "TEMPLATE exists previously: $TEMPLATEUUID .. removing ..."
 RESULT=`xe template-uninstall template-uuid=$TEMPLATEUUID --force`; 
 echo "RESULT: $RESULT"
fi; 

TEMPLATEUUID=`xe vm-clone uuid="$TEMPLATESOURCE" new-name-label="$TEMPLATENAME"`;
echo "TEMPLATEUUID: $TEMPLATEUUID"

VMUUID=`xe vm-install template=$TEMPLATENAME new-name-label=$VMNAME`;
echo "VMUUID: $VMUUID"

VMVHD=`xe vbd-list vm-name-label=$VMNAME params=vdi-uuid --minimal`.vhd;
echo "VMVHD: $VMVHD"

VIFUUID=`xe vif-create vm-uuid=$VMUUID network-uuid=$NETUUID mac=random device=0`;
echo "VIFUUID: $VIFUUID"

echo "Setting repositories and mirrors for kickstart installation ..."
xe vm-param-set uuid=$VMUUID other-config:install-repository=$MIRROR;
xe vm-param-set uuid=$VMUUID PV-args="console=hvc0 ks=$KICKFILE ksdevice=eth0 ip=dhcp noipv6";

echo "Adding memory and setting max/min memory values ..."
echo "vm-param-set memory-static-max=1GiB ..."
xe vm-param-set memory-static-max=1GiB uuid="$VMUUID"
echo "vm-param-set memory-dynamic-max=1GiB"
xe vm-param-set memory-dynamic-max=1GiB uuid="$VMUUID"
xe vm-param-set memory-dynamic-min=512MiB uuid="$VMUUID"
echo "vm-param-set memory-static-min=512MiB"
xe vm-param-set memory-static-min=512MiB uuid="$VMUUID"
echo "vm-param-set memory-static-min=512MiB"
xe vm-param-set memory-static-min=512MiB uuid="$VMUUID"
echo "Starting VM installation ..."
echo "Your prepared image is named '$VMVHD' and is located in the directory '$SR' "
xe vm-start uuid=$VMUUID
