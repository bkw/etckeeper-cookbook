name             "etckeeper_git"
maintainer       'Bernhard K. Weisshuhn'
maintainer_email 'bkw@codingforce.com'
license          'Apache 2.0'
description      'Installs/Configures etckeeper and remotes'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '2.0.0'
replaces         'etckeeper'
recipe           'etckeeper_git', 'Install etckeeper'
recipe           'etckeeper::enable', 'configure and enable etckeeper'
recipe           'etckeeper::chef', 'install chef-handler to commit changes by chef to etckeeper'

%w{redhat centos scientific fedora debian ubuntu arch freebsd amazon gentoo}.each do |os|
  supports os
end

depends 'chef_handler'
depends 'git'
depends 'ssh'

attribute 'etckeeper_git/author',
  :display_name => 'etckeeper commit author',
  :description => 'name and email address to use for git commits in etckeeper',
  :type => 'string',
  :default => "Etckeeper <root@{node[fqdn]}>"

attribute 'etckeeper_git/config',
  :display_name => 'etckeeper config file',
  :description => 'path to etckeeper.conf',
  :type => 'string',
  :default => '/etc/etckeeper/etckeeper.conf'

attribute 'etckeeper_git/avoid_daily_auto_commits',
  :display_name => 'disable etckeeper daily auto commits',
  :description => 'do not commit to etckeeper repository every day',
  :type => 'boolean',
  :default => true

attribute 'etckeeper_git/avoid_special_file_warning',
  :display_name => 'avoid special file warning',
  :description => 'suppress warnings about symlinks during etckeeper commits',
  :type => 'boolean',
  :default => true

attribute 'etckeeper_git/avoid_commit_before_install',
  :display_name => 'avoid commit before install',
  :description => 'do not commit changes before installing package',
  :type => 'boolean',
  :default => false

attribute 'etckeeper_git/highlevel_package_manager',
  :display_name => 'high level package manager',
  :description => 'Package manager to use in etckeeper. ' \
                  'Set automatically based on platform.',
  :type => 'string',
  :choice => ['yum', 'apt', 'emerge']

attribute 'etckeeper_git/loglevel_package_manager',
  :display_name => 'lowlevel packange manager',
  :description => 'Package database to use.' \
                  'Set automatically based on platform.',
  :type => 'string',
  :choice => ['rpm', 'dpkg', 'qlist']

