#!/bin/sh
#
# Very basic composer deployment.

# Determine if this pod runs a php image
if [ -f /tmp/src/composer.json ] ; then
	if [ -f /usr/local/etc/php/php.ini ] ; then
		echo "# Set HOME to a location where we can write:"
		export HOME=/tmp
	
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

		echo "# Test if there is a settings.ini file"
		if [ -f "/tmp/src/settings.ini" ]; then
			extraopts="-c /tmp/src/settings.ini"
		else
			extraopts=""
		fi
	
		echo "# Run composer activities before copying the data:"
		cd /tmp/src; php -d memory_limit=2G $extraopts /tmp/src/composer.phar install

		# Get rid of the extra settings.ini.
		if [ -f "/tmp/src/settings.ini" ]; then
			rm /tmp/src/settings.ini
		fi

		echo "# Move data to /var/www/html"
		cp -Rv /tmp/src/* /var/www/html
	else
		echo "# Not a PHP container, so composer is not necessary"
	fi
else
	echo "composer.json not found. No actions required"
fi

