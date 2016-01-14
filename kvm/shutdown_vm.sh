#!/usr/bin/env bash
#this script will shutdown a vm by name
#shutdown_vm.sh
REF_FILE_NFS_PATH=/test/disable_proxy.sh
vm_name=

close_vm()
{
	virsh shutdown $1
}	

check_vm_exist()
{
	result=`virsh domstate $1 2>&1`

	# vm is exist
	if [ $? -eq 0 ];then
		if [ "shut off" = "$result" ];then
			echo "vm $1 is already shutdown"
			exit 0
		else
			echo "vm $1 ==> $result"
			return 0
		fi
	else
		echo "vm $1 is not exist..."
		exit 1
	fi
}

main()
{
	vm_name=$1

	check_vm_exist $vm_name

	# remove proxy
	sh $REF_FILE_NFS_PATH $vm_name

	close_vm $vm_name
}
main $1