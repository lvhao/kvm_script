#!/usr/bin/env bash
#this script will clone a new vm from original vm
#create_vm.sh
ORI_VM=ori_vm
NEW_VM=new_vm
PROXY_TYPE=VM
DEFAULT_FILE_LOATION=/etc/libvirt/qemu/networks/default.xml
REF_FILE_NFS_PATH=/test/create_proxy.sh
ori_vm_name=
sub_ip_prefix=
new_vm_name=
vm_mac=
vm_ip=
sub_min=
sub_max=

init()
{
	sub_min=`egrep -o "start='[\.0-9]*'" $DEFAULT_FILE_LOATION | cut -d '=' -f 2 | grep -o "[^']*"`
	sub_ip_prefix=${sub_min%\.[0-9]*}
	sub_min=${sub_min##[0-9]*\.}
	echo "min_ip_value ==> $sub_ip_prefix.$sub_min"

	sub_max=`egrep -o "end='[\.0-9]*'" $DEFAULT_FILE_LOATION | cut -d '=' -f 2 | grep -o "[^']*"`
	sub_max=${sub_max##[0-9]*\.}
	echo "max_ip_value ==> $sub_ip_prefix.$sub_max"
}

validate_mac()
{
	egrep "<host.* mac='$1'" $DEFAULT_FILE_LOATION
	if [ $? -eq 0 ];then
		echo "mac $1 is unallocable"
		return 1
	else
		echo "mac $1 is allocable"
		return 0
	fi
}

set_mac()
{

	while [ true ];
	do
		# Make sure the first octet in your MAC address is EVEN (eg. 00:) 
		# as MAC addresses with ODD first-bytes (eg. 01:) are reserved for multicast communication
		vm_mac="00:"`head -5 /dev/urandom | cksum | md5sum | sed 's/\(..\)/&:/g' | cut -c1-14`
		validate_mac $vm_mac
		if [ $? -eq 0 ];then
			echo "mac $vm_mac is allocated to $new_vm_name"
			return 0
		fi
	done
}

validate_ip()
{
	egrep "<host.*ip='$1'" $DEFAULT_FILE_LOATION >/dev/null
	if [ $? -eq 0 ];then
		echo "ip $1 is unallocable"
		return 1
	else
		echo "ip $1 is allocabled to $new_vm_name"
		return 0
	fi
}

set_ip()
{
	while [ $sub_min -le $sub_max ];
	do
		vm_ip="${sub_ip_prefix}.$sub_min"
		validate_ip $vm_ip
		if [ $? -eq 0 ];then
			echo "ip $vm_ip is allocated to $new_vm_name"
			return 0
		else
			if [ $sub_min -eq $sub_max ];then
				echo "no enough ip to be allocated"
				exit 1
			fi
		fi
		sub_min=`expr $sub_min + 1`
	done
}

clone_vm()
{
	local ref_vm_mac="'${vm_mac}'"
	local ref_vm_ip="'${vm_ip}'"
	local ref_vm_name="'${new_vm_name}'"
	virsh net-update default add-last ip-dhcp-host --xml "<host mac=${ref_vm_mac} name=${ref_vm_name} ip=${ref_vm_ip} />" --live --config
	if [ $? -ne 0 ];then
		echo "add dhcp-host fail..."
		exit 1
	fi
	virt-clone --name=$new_vm_name --file=/home/sfadmin/vm/virtual_disk/$new_vm_name.img --mac=${vm_mac} --original=${ori_vm_name}
	virsh start $new_vm_name
}	

check_vm_exist()
{
	if [ "$ORI_VM" = "$2" ];then
		result=`virsh domstate $1 2>&1`
		if [ $? -eq 0 ];then
			if [ "running" = "$result" ];then
				echo "original vm is running , please shutdown it before clone"
				exit 1
			fi
			echo "domain $1 status ==> $result"
		else
			echo "original vm $1 is not exist..."
			exit 1
		fi
	else
		result=`virsh domstate $1 2>&1`
		if [ $? -eq 0 ];then
			echo "domain $1 is already exist ==> $result"
			exit 1
		else
			echo "begin create domain $1 ..."
		fi
	fi
}

add_vm_proxy()
{
	sh $REF_FILE_NFS_PATH $1 $new_vm_name $vm_ip $PROXY_TYPE
}


main()
{
	ori_vm_name=$1
	new_vm_name=$2

	check_vm_exist $ori_vm_name $ORI_VM
	check_vm_exist $new_vm_name $NEW_VM

	init
	set_mac
	set_ip

	add_vm_proxy
	clone_vm
}
main $1 $2