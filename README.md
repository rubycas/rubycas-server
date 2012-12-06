# RubyCAS-Server

## Copyright

Portions contributed by Matt Zukowski are copyright (c) 2011 Urbacon Ltd.
Other portions are copyright of their respective authors.

## Authors

See https://github.com/rubycas/rubycas-server/commits

## Installation

Example with mysql database:

1. `git clone git://github.com/rubycas/rubycas-server.git`
2. `cd rubycas-server`
3. `cp config/config.example.yml config.yml`
4. Customize your server by modifying the `config.yml` file. It is well commented but make sure that you take care of the following:
    1. Change the database driver to `mysql2`
    2. Configure at least one authenticator
    3. You might want to change `log.file` to something local, so that you don't need root. For example just `casserver.log`
    4. You might also want to disable SSL for now by commenting out the `ssl_cert` line and changing the port to something like `8888`
5. Create the database (i.e. `mysqladmin -u root create casserver` or whatever you have in `config.yml`)
6. Modify the existing Gemfile by adding drivers for your database server. For example, if you configured `mysql2` in config.yml, add this to the Gemfile: `gem "mysql2"`
7. Run `bundle install`
8. `bundle exec rubycas-server -c config.yml`

Your RubyCAS-Server should now be running. Once you've confirmed that everything looks good, try switching to a [Passenger](http://www.modrails.com/) deployment. You should be able to point Apache (or whatever) to the `rubycas-server/public` directory, and everything should just work.

Some more info is available at the [RubyCAS-Server Wiki](https://github.com/rubycas/rubycas-server/wiki).

If you have questions, try the [RubyCAS Google Group](https://groups.google.com/forum/?fromgroups#!forum/rubycas-server) or #rubycas on [freenode](http://freenode.net).

## License

RubyCAS-Server is licensed for use under the terms of the MIT License.
See the LICENSE file bundled with the official RubyCAS-Server distribution for details.
