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
  git_cmd = "git --git-dir=#{new_resource.directory}/.git"
  execute "git-add-remote-#{new_resource.name}" do
    command "#{git_cmd} config --add remote.origin.url #{new_resource.url}"
    not_if "#{git_cmd} config --get remote.origin.url #{new_resource.url}"
  end

  execute "git-set-branch-#{new_resource.branch}" do
    command "#{git_cmd} config --set branch.master.remote #{new_resource.branch}"
    not_if "#{git_cmd} config --get branch.master.remote #{new_resource.branch}"
  end
end

action :delete do
  git_cmd = "git --git-dir=#{new_resource.directory}/.git"
  execute "git-unset-remote-#{new_resource.name}" do
    command "#{git_cmd} config --unset remote.origin.url #{new_resource.url}"
    only_if "#{git_cmd} config --get remote.origin.url #{new_resource.url}"
  end

  execute "git-set-branch-#{new_resource.branch}" do
    command "#{git_cmd} config --add branch.master.remote #{new_resource.branch}"
    not_if "#{git_cmd} config --get branch.master.remote #{new_resource.branch}"
  end
end
