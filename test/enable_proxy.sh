#!/usr/bin/env bash
#this script will remove proxy
#remove_proxy.sh
DEFAULT_CONF_LOCATION=/etc/apache2/sites-available
PROXY_SOFFIC_CONF_NAME=proxy_soffic.conf
vm_user=

remove_proxy()
{
	# remove proxy
	sed -i "s/#\(ProxyPass.* \/$vm_user\)/\1/g" $DEFAULT_CONF_LOCATION/$PROXY_SOFFIC_CONF_NAME
	
	#reload apache2 conf
	service apache2 reload
}

main()
{

	vm_user=$1

	remove_proxy
}
main $1