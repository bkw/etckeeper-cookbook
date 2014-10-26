# endocing: UTF-8
#
# Cookbook Name:: etckeeper_git
# Attributes:: default
#
# Copyright 2012-2013, Steffen Gebert / TYPO3 Association
#                      Peter Niederlag / TYPO3 Association
# Copyright 2013,      Alexander Saharchuk <pioneer@saharchuk.com>
# Copyright 2014,      Bernhard K. Weisshuhn <bkw@codingforce.com>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

default['etckeeper_git']['git_author'] = nil
default['etckeeper_git']['config'] = '/etc/etckeeper/etckeeper.conf'
default['etckeeper_git']['avoid_daily_auto_commits'] = false
default['etckeeper_git']['avoid_special_file_warning'] = true
default['etckeeper_git']['avoid_commit_before_install'] = true
default['etckeeper_git']['remotes'] = ''

case node['platform']
when 'centos', 'redhat', 'amazon', 'scientific', 'fedora'
  default['etckeeper_git']['high_pckg_man'] = 'yum'
  default['etckeeper_git']['low_pckg_man'] = 'rpm'
when 'ubuntu', 'debian'
  default['etckeeper_git']['high_pckg_man'] = 'apt'
  default['etckeeper_git']['low_pckg_man'] = 'dpkg'
when 'gentoo'
  default['etckeeper_git']['high_pckg_man'] = 'emerge'
  default['etckeeper_git']['low_pckg_man'] = 'qlist'
end
