#!/usr/bin/env bash
#this script will remove proxy
#disable_proxy.sh
DEFAULT_CONF_LOCATION=/etc/apache2/sites-available
PROXY_SOFFIC_CONF_NAME=proxy_test.conf
vm_user=

disable_proxy()
{
	# remove proxy
	sed -i "s/ProxyPass.* \/$vm_user/#&/g" $DEFAULT_CONF_LOCATION/$PROXY_SOFFIC_CONF_NAME

	#reload apache2 conf
	service apache2 reload
}

main()
{

	vm_user=$1

	disable_proxy
}
main $1