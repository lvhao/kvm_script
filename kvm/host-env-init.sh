#!/usr/bin/env bash
# host-env-init.sh

NFS_SCRIPT=/test
SCRIPT_ORI=/test
BASE_ISO=/vm/iso
BASE_IMG=/vm/img
BASE_TPL=/vm/tpl
SERVER_TPL_FILE=ubuntu-server.xml
SERVER_TPL=xxx001
ori_ip=

####################################
#		func result handle
# param 	detail		default
#  $1 	  cmd result       1
#  $2 	    ok msg     "NOT SET"
#  $3 	    er msg	   "NOT SET"
#  $4	    er exit		 "OFF"
####################################
handle_result()
{
	
	if [ $1 -eq 0 ];then
		echo "\033[32m[OK]	 ${2} \033[0m"
	else
		echo "\033[31m[ERROR] ${3} \033[0m"
		if [ "$4" = "ON" ];then
			echo "\033[31msys exit! \033[0m"
			exit 1
		fi
	fi
}

step()
{
	echo "\033[32m  ${1}) ${2} \033[0m"
}

hardware_support()
{
	egrep '(vmx|svm)' --color=always /proc/cpuinfo >> /dev/null
	ret_code=$?
	ok_msg="Hardware support for virtualization of KVM"
	er_msg="Hardware does not support for virtualization of KVM"
	handle_result $ret_code "$ok_msg" "$er_msg" "ON"
}

install_apache2()
{
	apt-get install -y apache2 >> /dev/null
	ret_code=$?
	ok_msg="Install apache2 successfully"
	er_msg="Install apache2 failure"
	handle_result $ret_code "$ok_msg" "$er_msg" "ON"
}

install_kvm()
{
	apt-get install -y qemu-kvm >> /dev/null
	ret_code=$?
	ok_msg="Install qemu-kvm successfully"
	er_msg="Install qemu-kvm failure"
	handle_result $ret_code "$ok_msg" "$er_msg" "ON"
}

install_virt_mgr()
{
	apt-get install -y libvirt-bin >> /dev/null
	ret_code=$?
	ok_msg="Install virt-manager successfully"
	er_msg="Install virt-manager failure"
	handle_result $ret_code "$ok_msg" "$er_msg" "ON"
}

create_tpl()
{
	mkdir -p $BASE_ISO $BASE_IMG $BASE_TPL
	cp $SERVER_TPL_FILE $BASE_TPL/$SERVER_TPL_FILE
	qemu-img create -f qcow2 $BASE_IMG/server.img 10G
	virsh define $BASE_TPL/$SERVER_TPL_FILE
	virsh start $SERVER_TPL
	echo "======================dominfo========================"
	virsh dominfo $SERVER_TPL
}

client_nfs_map()
{
	mkdir -p $SCRIPT_ORI >>/dev/null 2>&1
	ret_code=$?
	ok_msg="create path $SCRIPT_ORI"
	er_msg="$SCRIPT_ORI is already exist"
	handle_result $ret_code "$ok_msg" "$er_msg"

	mount -t nfs ${ori_ip}:${SCRIPT_ORI} ${NFS_SCRIPT}
	ret_code=$?
	ok_msg="Mount ${ori_ip}:${SCRIPT_ORI} on ${NFS_SCRIPT}"
	er_msg="mount -t nfs ${ori_ip}:${SCRIPT_ORI} ${NFS_SCRIPT}"
	handle_result $ret_code "$ok_msg" "$er_msg" "ON"

	echo "${ori_ip}:${SCRIPT_ORI} ${NFS_SCRIPT} nfs defaults,  0 0" >> /etc/fstab
}

reinstall()
{
	echo "Begin clean,this may take a few minutes."

	step 1 "stop apache2"
	killall -9 apache2 >> /dev/null 2>&1

	step 2 "stop virt-manager"
	killall -9 virt-manager >> /dev/null 2>&1

	step 3 "umount ${ori_ip}:${SCRIPT_ORI}"
	umount ${ori_ip}:${SCRIPT_ORI} >> /dev/null 2>&1
	sed -i "s|^${ori_ip}:${SCRIPT_ORI}|#&|g" /etc/fstab

	step 4 "remove apache2,qemu-kvm,virt-manager"
	apt remove -y apache2 qemu-kvm virt-manager >> /dev/null 2>&1
	ret_code=$?
	ok_msg="Clean for reinstall successfully"
	er_msg="Reinstall error"
	handle_result $ret_code "$ok_msg" "$er_msg" "ON"

	virsh destroy $SERVER_TPL
}

input_ip()
{
	read -p "please input nfs-server ip: " ori_ip
	echo $ori_ip | grep -qE "^(25[0-5]|2[0-4][0-9]|[0-1]{1}[0-9]{2}|[1-9]{1}[0-9]{1}|[1-9])\.(25[0-5]|2[0-4][0-9]|[0-1]{1}[0-9]{2}|[1-9]{1}[0-9]{1}|[1-9]|0)\.(25[0-5]|2[0-4][0-9]|[0-1]{1}[0-9]{2}|[1-9]{1}[0-9]{1}|[1-9]|0)\.(25[0-5]|2[0-4][0-9]|[0-1]{1}[0-9]{2}|[1-9]{1}[0-9]{1}|[0-9])$"
	ret_code=$?
	ok_msg="IP $ori_ip format is right"
	er_msg="IP $ori_ip format is wrong"
	handle_result $ret_code "$ok_msg" "$er_msg"

	while [ $ret_code -ne 0 ];
	do
		input_ip
	done
}

# 1) check hardware support
# 2) install apache2
# 3) install kvm
# 4) install virt-manager
# 5) nfs map
# 6) create template
env_init()
{
	# must before reinstall action
	if [ -z "$2" ];then
		input_ip
	else
		ori_ip=$2
	fi

	if [ "$1" = "R" ];then
		reinstall
	fi
	echo "Begin install,this may take a few minutes."
	hardware_support
	install_apache2
	install_kvm
	install_virt_mgr
	client_nfs_map
	create_tpl
}

menu()
{
cat <<EOF
===============================
  	1) init-env
 	2) re-init-env
  	3) exit
===============================
EOF
	read -p "select your operate: " choice
	case $choice in
	1)
		env_init $1 $2
		menu $1
		;;
	2)
		env_init "R"
		menu $1
		;;
	3)
		exit 0
		;; 
	esac
}
menu $1