etckeeper_git Cookbook
======================

[![Supermarket](http://img.shields.io/cookbook/v/etckeeper_git.svg)][5]
[![Build Status](http://img.shields.io/travis/bkw/chef-etckeeper_git.svg)][6]
[![Code Coverage](http://img.shields.io/coveralls/bkw/chef-etckeeper_git.svg)][7]
[![Dependencies](http://img.shields.io/gemnasium/bkw/chef-etckeeper_git.svg)][8]


This cookbook installs and configures [etckeeper][1], a tool that lets you keep
your /etc directory under version control. For that, this cookbook supports
only `git` as a backend.

NOTES
-----
This cookbook is heavily based on the excellent [etckeeper cookbook][2] but
features a number of deviations, which are incompatible with the original.

Like its upstream, this cookbook features a chef handler, which will submit
changes done by chef runs into etckeeper's repository.

### Differences from upstream

* git support only
* LWRP `etckeeper_git_remote` for more flexible handling of git remotes
* support for multiple remotes
* do not overwrite /root/.ssh/config
* attributes renamed to match options in etckeeper.conf
* unused attributes removed


Requirements
------------
* Chef 11 or higher


Resources/Providers
-------------------
### etckeeper_git_remote
This resource manages git remotes for the etckeeper repository, that will
be pushed to on changes.

#### Actions
- `:create` - creates a git remote for etckeeper
- `:manage` - creates and updates the named git remote for etckeeper
- `:delete` - deletes the named git remote for etckeeper

#### Parameters
* `host` -  Hostname of server hosting the remote git repository
* `repository` - Name of the remote repository on the configured host
* `port` - Port number where the remote repository is hosted.
  The default is `22` (ssh).
* `user` - Ssh username to log into the remote repository.
  The default is `git`
* `directory` - Base directory of the local etckeeper respository.
  Defaults to `/etc`
* `branch` - Name of the branch to push to on the remote
  Defaults to `master`
* `sshkey` - Contents of private key to use for pushing.
  Do _not_ set this from a client attribute, as these can be read from all
  clients of your chef server. The use of [chef-vault][3] is recommended
  instead.

#### Example
``` ruby
# push changes to github
etckeeper_git_remote 'github' do
  host 'github.com'
  repository 'myorg/etckeeper-myhost'
  sshkey "-----BEGIN RSA PRIVATE KEY-----\n[…]"
  action :create
end

# also push to our private server
etckeeper_git_remote 'private' do
  host 'git.example.com'
  port 2222
  user 'gitlab'
  repository 'etckeepers/myhost'
  branch 'production'
  sshkey "-----BEGIN RSA PRIVATE KEY-----\n[…]"
end
```

Recipes
-------

* `default` - Install git and etckeeper
* `enable` - Initialize and enable etckeeper for normal activity
* `chef` - Set up chef handlers to commit to etckeeper after chef client runs


Attributes
----------
Attributes have default values set in `attributes/default.rb`.

* `node['etckeeper_git']['author']`
  Author information to use for git commits.
  Default: `Etckeeper <root@$FQDN>`

* `node[etckeeper_git]['config']`
  Main configuration file of etckeeper.
  Default: `/etc/etckeeper/etckeeper.conf`

* `node[etckeeper_git]['avoid_daily_auto_commits']`
  Do not commit changes to etckeeper every day.
  Default: `false`

* `node['etckeeper_git']['avoid_special_file_warning']`
  Set `AVOID_SPECIAL_FILE_WARNING` in `etckeeper.conf`.
  Without this, etckeeper is likely to complain about symlinks.
  Default: `true`

* `node['etckeeper_git']['avoid_commit_before_install']`
  See `AVOID_COMMIT_BEFORE_INSTALL` in etckeeper docs.
  Default: `false`

* `node['etckeeper_git']['highlevel_package_manager']`
  Package manager to use. See `HIGHLEVEL_PACKAGE_MANAGER` in etckeeper docs.
  Set automatically based on platform.

* `node['etckeeper_git']['loglevel_package_manager']`
  Package database to use. See `LOWLEVEL_PACKAGE_MANAGER` in etckeeper docs.
  Set automatically based on platform.

Dependencies
============

* `recipe['chef_handler']`
* `recipe['git']`



## Related Cookbooks



## Contributing
See [CONTRIBUTING.md][4] for guidelines.

## Credits

This cookbook is based on the [etckeeper cookbook][2]. Here is the original credits section:

--------------------------------

Thanks to [alekschumakov88](https://github.com/alekschumakov88) for begining.
And thank maintainers from [TYPO3 Association](https://github.com/TYPO3-cookbooks):
* *Steffen Gebert*
* *Bastian Bringenberg*
* *Peter Niederlag*

--------------------------------

## License and Author

Author:: Bernhard K. Weisshuhn

Copyright 2012-2013, Steffen Gebert / TYPO3 Association
Copyright 2012-2013, Peter Niederlag / TYPO3 Association
Copyright 2013,      Alexander Saharchuk <pioneer@saharchuk.com>
Copyright 2014,      Bernhard K. Weisshuhn <bkw@codingforce.com>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and

[1]: https://github.com/joeyh/etckeeper
[2]: https://supermarket.getchef.com/cookbooks/etckeeper
[3]: https://github.com/opscode-cookbooks/chef-vault
[4]: https://github.com/bkw/cookbook-etckeeper_git/blob/master/CONTRIBUTING.md
[5]: https://supermarket.getchef.com/cookbooks/etckeeper_git
[6]: http://travis-ci.org/bkw/chef-etckeeper_git
[7]: https://coveralls.io/r/bkw/chef-etckeeper_git
[8]: https://gemnasium.com/bkw/chef-etckeeper_git
