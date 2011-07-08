# RubyCAS-Server ![http://stillmaintained.com/gunark/rubycas-server](http://stillmaintained.com/gunark/rubycas-server.png)

## Copyright

Portions contributed by Matt Zukowski are copyright (c) 2010 Urbacon Ltd.
Other portions are copyright of their respective authors.

## Authors

See http://github.com/gunark/rubycas-server/commits/

## Installation

on ubuntu using unicorn:

	git clone git@github.com:seven1240/rubycas-server.git
	cd rubycas-server
	sudo bundle install

If it complains mysql connectivity, do this

	apt-get install libmysqlclient16-dev
	sudo gem install mysql2

copy resources/config.example.yml into /etc/rubycas-server/config.yml, there's way to put the config in other place, yet to document. Change the config to meet your requests.

You might also want to change config/unicorn.conf

	unicorn -D -c config/unicorn.conf

For info and detailed installation instructions please see http://code.google.com/p/rubycas-server

## License

RubyCAS-Server is licensed for use under the terms of the MIT License. 
See the LICENSE file bundled with the official RubyCAS-Server distribution for details.
