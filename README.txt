---------------------------------------------------------
 Stonith Plugin Agent for VMWare VM VCenter SOAP Fencing
---------------------------------------------------------
Author: 
  Olaf Reitmaier <olafrv@gmail.com>
Version:
  16/Jan/2015
License: 
  Creative Common Attribution-ShareAlike 4.0 International (CC BY-SA 4.0)
  http://creativecommons.org/licenses/by-sa/4.0/

------------------------------------------
 Tested on the following virtual platform
------------------------------------------
- Ubuntu Linux Server Edition 14.04 64 bits (Peacemaker/Heartbeat).
- SUSE Enterprise Linux 11 SP3 64 bits (Peacemaker/Heartbeat).
- VMWare ESXi/VCenter 5.1 U1 (Used as Fencing Device)

---------
 History
---------

- 14/Jan/2015 - Testing on Ubuntu Linux 14.04 64 bits.
- 15/Jan/2015 - Implementation and testing on SLES Linux 11 SP3 64 bits.

---------------------
 Plugin Architecture
---------------------

stonithd (Cluster Fencing Daemon)
  -> /usr/lib/stonith/plugins/external/fence_vmware_soap (Stonith Plugin Agent)
    -> /usr/sbin/fence_vmware_soap (SOAP Fence Request, provided by fence-agents)
	   -> VMWareVCenter (SOAP Web Service, Authentication, Search, Triggering)
	      -> VMWare ESXi Hypervisor (Virtual Machine On/Off)

--------------
 Requirements
--------------
 
- Fully functional Linux operating system (VMWare Virtual Machines).
- Fully functional Peacemaker/Heartbeat cluster (Know How About It).

------------------------------
 Packages needed Ubuntu 14.04
------------------------------

fence-agents in its default version 3.1.5 and the python suds library:
apt-get install python-suds fence-agents

-----------------------------
 Packages needed SUSE 11 SP3
-----------------------------
fence-agents, version 3.1.6 is provided by default but a newer version is needed 4.0 included in OpenSUSE 13.2:
http://software.opensuse.org/package/fence-agents?search_term=fence-agents

In order to download the package execute the following command:
wget http://download.opensuse.org/repositories/openSUSE:/13.2/standard/x86_64/fence-agents-4.0.10-2.4.1.x86_64.rpm

Many fence agents depends on Python libraries, some could be installed directly:
zypper install python-curl python-openssl python-pexpect python-request

And other must be installed using python setup tools (https://pypi.python.org/pypi/setuptools) as follows:
wget https://bootstrap.pypa.io/ez_setup.py
python ez_setup.py

Now you can install the required libraries "request" and "suds" from the official repositories:
easy_install requests suds

Now cleanly you can install the "fence-agents" package downloaded previously:
rpm -i --nodeps fence-agents-4.0.10-2.4.1.x86_64.rpm

---------------------
 Plugin Installation
---------------------

*** CAUTION: Use the version 15/01/2015 of fence_vmware_soap stonith plugin agent, which includes compatibility for the fence_vmware_soap script provided by both fence-agents versions (3.X and 4.X). ***

Copy the fence_vmware_soap (bash script) stonith plugin agent to ONE of the following EXISTENT directories:
- /usr/lib/stonith/plugins/external/
- /usr/lib64/stonith/plugins/external/ 

For more information, about the stonith plugin agents visit the following links:
- 8.1. STONITH Agents: https://doc.opensuse.org/products/draft/SLE-HA/SLE-ha-guide_sd_draft/cha.ha.agents.html
- External STONITH Plugins: http://www.linux-ha.org/ExternalStonithPlugins

Give the following permissions:
chmod 755 /usr/lib/stonith/plugins/external/fence_vmware_soap

Check correct plugin installation and detection by stonith:
stonith -L | grep fence_vmware_soap

The output should be:
external/fence_vmware_soap

Check correct parameter listing for the plugin agent:
stonith -t "external/fence_vmware_soap" -n

The output should be:
hostlist  vcenterip  username  password

----------------------
 Plugin Configuration
----------------------

Extract the cluster node VMWare VM UUID BIOS (Case Sensitive Output) on each virtual machine:
dmidecode | grep -i uuid | awk '{print $2}' | tr '[:upper:]' '[:lower:]'

The output should be something like this (and different for each cluster node):
4233cc22-770f-3027-c090-889054979c45

Extract the cluster node names (the same defined in the cluster configuration, example: node1, node2):
uname -n

Determine the VMWare VCenter IPv4 address controlling the VMWare ESX Hypervisor Hosts serving the Virtual Machines:
<VCenterIP> (Ask the virtualization platform administrator)

Obtain the VMWare VCenter credentials (VCenterUser and VCenterPassword) with fencing permissions, for more information look at:
  
  "What user permissions/roles are required for the VMware vCenter 
  user account to perform fence action using fence_vmware_soap?"
  https://access.redhat.com/solutions/82333
  
-------------
 Plugin Test
-------------

*** NOTICE: The following test DO NOT require cluster configuration modifications!. ***

First, test the correct function of the command "fence_vmware_soap" provided by package "fence-agents" issuing the following command (CAUTION: Cluster nodes will be restarted!):

On fence-agents 3.X issuing the command:
fence_vmware_soap -o reboot -a <VCenterIP> -l "<VCenterUser>" -p "<VCenterPassword>" -z -U "<UUID>"

On fence-agents 4.X issuing the command:
fence_vmware_soap -o reboot -a <VCenterIP> -l "<VCenterUser>" -p "<VCenterPassword>" -z --ssl-insecure -n "<UUID>"

Second, test fencing plugin agent (CAUTION: Cluster nodes will be restarted):

stonith -t "external/fence_vmware_soap" hostlist="node1,uuid1;node2,uuid2" vcenterip="<VCenterIP>" username="<VCenterUser>" password="<VCenterPassword>" <node1|node2>

The ouput of this command should be something like this (the last line is the must important):

info: external_run_cmd: '/usr/lib/stonith/plugins/external/fence_vmware_soap reset vsaporat1' output: Success: Rebooted

The following messages can be safely ignored as they only warns about the "--ssl-insecure" parameter included by plugin in order to allow the use of self-signed certificates for the SSL tunnel:
/usr/local/lib64/python2.6/site-packages/requests-2.5.1-py2.6.egg/requests/packages/urllib3/connectionpool.py:734: InsecureRequestWarning: Unverified HTTPS request is being made. Adding certificate verification is strongly advised. See: https://urllib3.readthedocs.org/en/latest/security.html

The plugin agent output to syslog (or messages) entries tagged as "fence_vmware_soap" for debugging purposes:

Jan 13 17:04:59 node1 stonith-ng[1284]:  notice: stonith_device_register: Added 'fence_vmware_soap1' to the device list (1 active devices)
Jan 13 17:05:02 node1 stonith-ng[1284]:   notice: stonith_device_register: Device 'fence_vmware_soap1' already existed in device list (1 active devices)
Jan 13 17:05:03 node1 crmd[1288]:   notice: process_lrm_event: LRM operation fence_vmware_soap1_start_0 (call=23, rc=0, cib-update=14, confirmed=true) ok
Jan 13 17:09:06 node1 fence_vmware_soap: hostlist: node1#012node2
Jan 13 17:09:06 node1 stonith-ng[1284]:   notice: can_fence_host_with_device: fence_vmware_soap1 can fence node2: dynamic-list
Jan 13 17:09:06 node1 fence_vmware_soap: hostlist: node1,uuid1;node2,uuid2
Jan 13 17:09:06 node1 fence_vmware_soap: fencing: VCenterIP VCenterUser reboot uuid2
Jan 13 17:09:25 node1 stonith: [1996]: info: external_run_cmd: '/usr/lib/stonith/plugins/external/fence_vmware_soap reset node2' output: Success: Rebooted

If all the previous test are passed so the nodes are correctly restarted, everything is correct.

---------------------------------------------
 Plugin Activation (Fencing Device Creation)
---------------------------------------------

*** NOTICE: The following test DO REQUIRE cluster configuration modifications!. ***

It is important to DELETE current stonith devices and DISABLE stonith components to avoid fencing device conflicts:

crm configure 
property stonith-enabled=false
commit
exit

After the previous configuration, both nodes should be restarted.

Declare the VMWare Fencing Device in the cluster:

crm configure
primitive fence_vmware_soap1 stonith:external/fence_vmware_soap \
        params hostlist="node1,uuid1;node2,uuid2" vcenterip="<VCenterIP>" username="<VCenterUser>" password="<VCenterPassword>"
commit
exit

Clone the VMWare Fencing Device to set it up and available on all cluster nodes:
crm configure
clone clone_fence_vmware fence_vmware_soap1
commit
exit

For more infomation this cloning approach visit:
  - "Fencing and Stonith" visit: http://clusterlabs.org/doc/crm_fencing.html):

Check if the fencing device (fence_vmware_soap1) is available and working in the cluster:
stonith_admin -L

Check if the fencing device (fence_vmware_soap1) is available and can fence all nodes:
stonith_admin --list=<node1|node2>

Now activate fencing mechanism:

crm configure 
property stonith-enabled=true
property stonith-action="reboot"
commit
exit

After the previous configuration, both nodes should be restarted, in order to do the final certification tests.

First, disable heartbeat NIC/Ethernet (ifdown eth0) in one node, then you should see in the syslog the same entries about fencing actions shown at the previous fencing tests.

Finally, do the same in the other node.

Done!.
