#!/usr/bin/env bash
# soff-cloud-env-init.sh

script_ori=/home/lvhao/Desktop/cloud_mgr/vm_script
script_nfs=/soff

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


install_apache2()
{
	apt-get install -y apache2 >> /dev/null
	ret_code=$?
	ok_msg="Install apache2 successfully"
	er_msg="Install apache2 failure"
	handle_result $ret_code "$ok_msg" "$er_msg" "ON"
}

install_nfs()
{
	apt-get install -y nfs-kernel-server nfs-common rpcbind >> /dev/null
	ret_code=$?
	ok_msg="Install nfs successfully"
	er_msg="Install nfs failure"
	handle_result $ret_code "$ok_msg" "$er_msg" "ON"
}

install_virt_mgr()
{
	apt-get install -y virt-manager >> /dev/null
	ret_code=$?
	ok_msg="Install virt-manager successfully"
	er_msg="Install virt-manager failure"
	handle_result $ret_code "$ok_msg" "$er_msg" "ON"
}

server_nfs_map()
{
	mkdir -p $script_nfs >> /dev/null
	mount --bind ${script_ori}/ ${script_nfs}
	ret_code=$?
	ok_msg="Mount ${script_ori}/ on ${script_nfs}"
	er_msg="mount --bind ${script_ori}/ ${script_nfs}"
	handle_result $ret_code "$ok_msg" "$er_msg" "ON"

	echo "${script_ori}/ ${script_nfs} none defaults,bind 0 0" >> /etc/fstab
	echo "${script_nfs}  *(ro,sync,fsid=0,all_squash,no_subtree_check)" >> /etc/exports
	service rpcbind restart
	service nfs-kernel-server restart
}

reinstall()
{
	echo "Begin clean,this may take a few minutes."

	step 1 "stop apache2"
	killall -9 apache2 >> /dev/null 2>&1

	step 2 "stop virt-manager"
	killall -9 virt-manager >> /dev/null 2>&1

	step 3 "stop nfs"
	service nfs-kernel-server stop >> /dev/null 2>&1
	service rpcbind stop >> /dev/null 2>&1

	step 4 "umount ${script_ori}/"
	umount ${script_ori}/ >> /dev/null 2>&1

	sed -i "{ 
		s|^${script_ori}/|#&|g
	}" /etc/fstab

	sed -i "{
		s|^${script_nfs}|#&|g
	}" /etc/exports

	step 5 "remove apache2,nfs,virt-manager"
	apt remove -y apache2 nfs-common nfs-kernel-server rpcbind virt-manager >> /dev/null 2>&1
	ret_code=$?
	ok_msg="Clean for reinstall successfully"
	er_msg="Reinstall error"
	handle_result $ret_code "$ok_msg" "$er_msg" "ON"
}

start_virt_mgr()
{
	virt-manager >> /dev/null 2>&1

	if [ $? -ne 0 ];then
		echo "open virt-manager fail,try reinstalling..."
		install_virt_mgr
		virt-manager
	fi	
}

# 1) install virt-manager
# 2) install apache2
# 3) install nfs server
# 4) map nfs 
env_init()
{
	if [ "$1" = "R" ];then
		reinstall
	elif [ "$1" = "M" ]; then
		start_virt_mgr
		exit 0
	fi

	echo "Begin install,this may take a few minutes."
	install_apache2
	install_virt_mgr
	install_nfs
	server_nfs_map
}

menu()
{
cat <<EOF
===============================
  	1) init-env
 	2) re-init-env
  	3) open virt-manager
  	4) exit
===============================
EOF
	read -p "select your operate: " choice
	case $choice in
	1)
		env_init
		menu $1
		;;
	2)
		env_init "R"
		menu $1
		;;
	3)
		start_virt_mgr
		menu $1
		;;
	4)
		exit 0
		;; 
	esac
}
menu $1