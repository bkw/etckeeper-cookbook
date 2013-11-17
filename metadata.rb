name             "etckeeper"
maintainer       "Alexander Saharchuk"
maintainer_email "alexander@saharchuk.com"
license          "Apache 2.0"
description      "Installs/Configures etckeeper"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "0.0.6"

depends "chef_handler"
depends "cron"
depends "git"

# TODO:
# 1. support OS
