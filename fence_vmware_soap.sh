#!/bin/bash

##
# This STONITH script executes fencing via fence_vmware_soap
# agents available from package 'fence-agents'.
#
# Author:
#  Olaf Reitmaier <olafrv@gmail.com>
# Version:
#  16/Jan/2015
# License:
#  GNU General Public License (GPL) v3
#  http://www.gnu.org/licenses/gpl.html
###

# Main code
case $1 in
gethosts)
    hosts=$(echo "$hostlist" | tr ";" "\n" | cut -d"," -f1)
    echo "$hosts"
    logger -t fence_vmware_soap -p syslog.info "hostlist: $hosts"
    exit 0
    ;;
status)
    exit 0
    ;;
on|off|reset)
    action=$1
    if [ "$action" == "reset" ]
    then
	action="reboot"
    fi
    host=$2
    uuid=$(echo "$hostlist" | tr ";" "\n" | grep "$host" | cut -d"," -f2)
    logger -t fence_vmware_soap -p syslog.info "hostlist: $hostlist"
    logger -t fence_vmware_soap -p syslog.warn "fencing: $vcenterip $username $action $host $uuid"
	if fence_vmware_soap --help | grep "\-\-uuid" > /dev/null
	then
		logger -t fence_vmware_soap -p syslog.info "fencing as version 3 mode"
		fence_vmware_soap --ip "$vcenterip" --ssl \
			--username "$username" --password="$password" \
				--action "$action" --uuid "$uuid"
	else
		logger -t fence_vmware_soap -p syslog.info "fencing as version 4 mode"
		fence_vmware_soap --ip "$vcenterip" --ssl --ssl-insecure \
			--username "$username" --password="$password" --action "$action" \
				--plug "$uuid"
	fi
    exit $?
    ;;
getconfignames)
    echo "hostlist vcenterip username password"
    exit 0
    ;;
getinfo-devid)
    echo "fence_vmware_soap vcenter device"
    exit 0
    ;;
getinfo-devname)
    echo "fence_vmware_soap vcenter external device"
    exit 0
    ;;
getinfo-devdescr)
    echo "This STONITH script executes fencing via fence_vmware_soap"
    echo "agents available from package 'fence-agents' (RedHat)."
    exit 0
    ;;
getinfo-devurl)
    echo "http://www.olafrv.com/"
    exit 0
    ;;
getinfo-xml)
    cat << FULLXML
<parameters>
<parameter name="hostlist" unique="1" required="1">
<content type="string" />
<shortdesc lang="en">
The list of fenceable hosts
</shortdesc>
<longdesc lang="en">
Example: host1:uuid1,host2:uuid2
uuid taken from (VMWare UUID BIOS) or in the VM with this command:
dmidecode | grep -i uuid | awk '{print $2}' | tr '[:upper:]' '[:lower:]' 
</longdesc>
</parameter>
<parameter name="vcenterip" unique="1" required="1">
<content type="string" />
<shortdesc lang="en">
VMWare VCenter IPv4 Address (Fencing Device)
</shortdesc>
<longdesc lang="en">
What user permissions/roles are required for the VMware vCenter
user account to perform fence action using fence_vmware_soap?
https://access.redhat.com/solutions/82333/
</longdesc>
</parameter>
<parameter name="username">
<content type="string" />
<shortdesc lang="en">
VMWare VCenter User
</shortdesc>
<longdesc lang="en">
VMWare VCenter User
</longdesc>
</parameter>
<parameter name="password">
<content type="string" />
<shortdesc lang="en">
VMWare VCenter Password
</shortdesc>
<longdesc lang="en">
VMWare VCenter Password
</longdesc>
</parameter>
</parameters>
FULLXML
    exit 0
    ;;
*)
    exit 1
    ;;
esac
