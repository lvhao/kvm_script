#!/usr/bin/env bash
#this script will add vm proxy in host machine
#create_proxy.sh
DEFAULT_CONF_LOCATION=/etc/apache2/sites-available
DEFAULT_CONF_NAME=000-default.conf
PROXY_SOFFIC_CONF_NAME=proxy_soffic.conf

vm_user=
vm_ip=
suffix=
create_conf_file()
{
	# file is exist
	if [ -e $DEFAULT_CONF_LOCATION/$PROXY_SOFFIC_CONF_NAME ];then
		echo "file is already exist"
		return 1
	else
		cp $DEFAULT_CONF_LOCATION/$DEFAULT_CONF_NAME $DEFAULT_CONF_LOCATION/$PROXY_SOFFIC_CONF_NAME
		echo "creaete file suc"
		return 0
	fi
}

add_proxy()
{
	create_conf_file

	# return 0 means the conf file is first created,need to be init
	# return 1 means the conf file has been created,don't need to be init

	# init conf
	# 1) enable ProxyPreserveHost On
	# 2) enable ProxyRequests Off
	# 3) disable ServerAdmin webmaster@localhost
    # 4) disable DocumentRoot /var/www/html
	# 5) delete 000-default.conf in sites-enable directory
	# 6) make a soft link for custom proxy conf in sites-enable directory 
	
	if [ $? -eq 0 ];then
		sed -i "{
			s/ServerAdmin/#&/g
			s/DocumentRoot/#&/g
			/<\/VirtualHost/i\ \tProxyPreserveHost On
			/<\/VirtualHost/i\ \tProxyRequests Off
		}" $DEFAULT_CONF_LOCATION/$PROXY_SOFFIC_CONF_NAME

		rm -rf ${DEFAULT_CONF_LOCATION%/*}/sites-enable/$DEFAULT_CONF_NAME
		ln -s  $DEFAULT_CONF_LOCATION/$PROXY_SOFFIC_CONF_NAME ${DEFAULT_CONF_LOCATION%/*}/sites-enabled/

	fi

	# add proxy
	sed -i "{
		/<\/VirtualHost>/i\ \tProxyPass \/$vm_user http:\/\/$vm_ip$suffix
		/<\/VirtualHost>/i\ \tProxyPassReverse \/$vm_user http:\/\/$vm_ip$suffix
	}" $DEFAULT_CONF_LOCATION/$PROXY_SOFFIC_CONF_NAME
	
	# reload apache2 conf
	service apache2 reload
}

main()
{
	PROXY_TYPE=VM
	vm_user=$1
	vm_ip=$2
	if [ "$3" = "$PROXY_TYPE" ];then
		suffix=
	else
		suffix=/$vm_user
	fi
	add_proxy

}
main $1 $2 $3