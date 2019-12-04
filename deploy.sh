#!/bin/sh
#
# Very basic composer deployment.

# Determine if this pod runs a php image
if [ -f /tmp/src/composer.json ] ; then
	if [ -f /usr/local/etc/php/php.ini ] ; then
		echo "# Set HOME to a location where we can write:"
		export HOME=/tmp
	
		cat /usr/local/etc/php/conf.d/specials.ini
	
		echo "# Get the signature for verification of composer:"
		EXPECTED_SIGNATURE="$(wget -q -O - https://composer.github.io/installer.sig)"
	
		echo "# Get composer setup:"
		php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
	
		echo "# Get the signature of the setupfile:"
		ACTUAL_SIGNATURE="$(php -r "echo hash_file('sha384', 'composer-setup.php');")"
	
		echo "# Verify composer-setup.php:"
		if [ "$EXPECTED_SIGNATURE" != "$ACTUAL_SIGNATURE" ]
		then
		    >&2 echo 'ERROR: Invalid installer signature'
		    rm composer-setup.php
		    exit 1
		fi
	
		echo "# Run composer setup and remove composer-setup.php afterwards:"
		php composer-setup.php --quiet --install-dir=/tmp/src/
		RESULT=$?
		rm composer-setup.php
	
		echo "# Run composer activities before copying the data:"
		cd /tmp/src; php -d memory_limit=2G /tmp/src/composer.phar install
	else
		echo "# Not a PHP container, so composer is not necessary"
	fi
else
	echo "composer.json not found. No actions required"
fi

