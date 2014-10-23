# encoding: UTF-8
#
# Cookbook Name:: etckeeper
# Recipe:: config
#
# Copyright 2012-2013, Steffen Gebert / TYPO3 Association
#                      Peter Niederlag / TYPO3 Association
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

include_recipe 'ssh'

git_cmd = 'git --git-dir=/etc/.git'

directory node['etckeeper']['dir'] do
  owner 'root'
  group 'root'
  mode '0755'
  recursive true
end

template node['etckeeper']['config'] do
  source 'etckeeper.conf.erb'
  mode 0644
end

execute 'etckeeper init' do
  only_if { node['etckeeper']['vcs'] == 'git' }
  not_if { File.exist?('/etc/.git/config') }
  cwd '/etc'
end

email = node['etckeeper']['git_email']
execute 'etckeeper_set_git_email' do
  command "#{git_cmd} config user.email '#{email}'"
  only_if { node['etckeeper']['vcs'] == 'git' }
  not_if "#{git_cmd} config --get user.email | fgrep -q '#{email}'"
end

etckeeper_git_remote node['etckeeper']['git_host'] do
  host node['etckeeper']['git_host']
  repository node['etckeeper']['git_repo']
  sshkey 'testing-key'
  branch node['etckeeper']['git_branch']
  user node['etckeeper']['git_user']
  action :create
  only_if do
    node['etckeeper']['use_remote'] && node['etckeeper']['vcs'] == 'git'
  end
end

template '/etc/cron.daily/etckeeper' do
  source 'etckeeper.erb'
  mode '0755'
  owner 'root'
  only_if { node['etckeeper']['daily_auto_commits'] }
end
