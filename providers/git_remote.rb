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

use_inline_resources if defined?(use_inline_resources)

# Support whyrun
def whyrun_supported?
  true
end

action :create do
  if @current_resource.exists
    Chef::Log.info "#{ @new_resource } already exists - nothing to do."
  else
    converge_by("Create #{ @new_resource }") do
      add_git_remote
      add_git_remote_branch
    end
  end
end

action :delete do
  if @current_resource.exists
    converge_by("Delete #{ @new_resource }") do
      delete_git_remote
      delete_git_remote_branch
    end
  else
    Chef::Log.info "#{ @new_resource } doesn't exists - can't delete."
  end
end

def load_current_resource
  @current_resource = Chef::Resource::EtckeeperGitRemote.new(@new_resource.name)
  @current_resource.name(@new_resource.name)
  @current_resource.directory(@new_resource.directory)
  @current_resource.url(@new_resource.url)
  @current_resource.branch(@new_resource.branch)

  @current_resource.exists = (
    remote_exists?(@current_resource.url, @current_resource.directory) &&
    branch_exists?(@current_resource.branch, @current_resource.directory)
  )
end

private

def remote_exists?(url, directory)
  git_cfg = "git --git-dir=#{directory}/.git config"
  cmd = Mixlib::ShellOut.new(
    "#{git_cfg} --get remote.origin.url #{url}"
  )
  cmd.run_command
  cmd.exitstatus == 0
end

def branch_exists?(branch, directory)
  git_cfg = "git --git-dir=#{directory}/.git config"
  cmd = Mixlib::ShellOut.new(
    "#{git_cfg} --get branch.master.remote #{branch}"
  )
  cmd.run_command
  cmd.exitstatus == 0
end

def add_git_remote
  return if remote_exists?(new_resource.url, new_resource.directory)
  git_cfg = "git --git-dir=#{new_resource.directory}/.git config"
  cmd = Mixlib::ShellOut.new(
    "#{git_cfg} --add remote.origin.url #{new_resource.url}"
  )
  cmd.run_command
  cmd.exitstatus == 0
end

def add_git_remote_branch
  return if branch_exists?(new_resource.branch, new_resource.directory)
  git_cfg = "git --git-dir=#{new_resource.directory}/.git config"
  cmd = Mixlib::ShellOut.new(
    "#{git_cfg} --set branch.master.remote #{new_resource.branch}"
  )
  cmd.run_command
  cmd.exitstatus == 0
end
