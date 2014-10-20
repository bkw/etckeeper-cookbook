# encoding: utf-8
#
# Cookbook Name:: etckeeper
# Provider:: git_remote
#
# Copyright 2014, Bernhard K. Weisshuhn <bkw@codingforce.com>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

action :create do
  git_cfg = "git --git-dir=#{new_resource.directory}/.git config"

  remote_exists = Mixlib::ShellOut.new(
    "#{git_cfg} --get remote.origin.url #{new_resource.url}"
  )

  branch_exists = Mixlib::ShellOut.new(
    "#{git_cfg} --get branch.master.remote #{new_resource.branch}"
  )

  remote_exists.run_command
  execute "git-add-remote-#{new_resource.name}" do
    command "#{git_cfg} --add remote.origin.url #{new_resource.url}"
    only_if { remote_exists.exitstatus == 1 }
  end

  branch_exists.run_command
  execute "git-set-branch-#{new_resource.branch}" do
    command "#{git_cfg} --set branch.master.remote #{new_resource.branch}"
    only_if { branch_exists.exitstatus == 1 }
  end

  new_resource.updated_by_last_action(
    remote_exists.exitstatus == 1 || branch_exists.exitstatus == 1
  )
end

action :delete do
  git_cfg = "git --git-dir=#{new_resource.directory}/.git config"

  remote_exists = Mixlib::ShellOut.new(
    "#{git_cfg} --get remote.origin.url #{new_resource.url}"
  )

  branch_exists = Mixlib::ShellOut.new(
    "#{git_cfg} --get branch.master.remote #{new_resource.branch}"
  )

  remote_exists.run_command
  execute "git-unset-remote-#{new_resource.name}" do
    command "#{git_cfg} --unset remote.origin.url #{new_resource.url}"
    only_if { remote_exists.exitstatus == 0 }
  end

  branch_exists.run_command
  execute "git-set-branch-#{new_resource.branch}" do
    command "#{git_cfg} --unset branch.master.remote #{new_resource.branch}"
    only_if { branch_exists.exitstatus == 0 }
  end

  new_resource.updated_by_last_action(
    remote_exists.exitstatus == 1 || branch_exists.exitstatus == 1
  )
end
