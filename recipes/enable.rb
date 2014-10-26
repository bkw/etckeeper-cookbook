# encoding: UTF-8
#
# Cookbook Name:: etckeeper_git
# Recipe:: enable
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
#

include_recipe 'etckeeper_git'
include_recipe 'ssh'

hostname = node['fqdn'] || "#{node['hostname']}.local"
node.default['etckeeper_git']['author'] = "Etckeeper <root@#{hostname}>"
directory ::File.dirname(node['etckeeper_git']['config']) do
  owner 'root'
  group 'root'
  mode '0755'
  recursive true
  action :create
end

template node['etckeeper_git']['config'] do
  source 'etckeeper.conf.erb'
  mode 0644
end

execute 'etckeeper init' do
  not_if { File.exist?('/etc/.git/config') }
  cwd '/etc'
end

template '/etc/cron.daily/etckeeper' do
  source 'cron.daily/etckeeper.erb'
  mode '0755'
  owner 'root'
  not_if { node['etckeeper_git']['avoid_daily_auto_commits'] }
end
