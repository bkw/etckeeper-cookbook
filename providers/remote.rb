# encoding: utf-8
#
# Cookbook Name:: etckeeper_git
# Provider:: remote
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
      add_ssh_key
      set_ssh_config
      add_git_remote
      add_git_remote_branch
      use_remote
    end
  end
end

action :delete do
  if @current_resource.exists
    converge_by("Delete #{ @new_resource }") do
      delete_git_remote_branch
      delete_git_remote
      dont_use_remote
      delete_ssh_config
      delete_ssh_key
    end
  else
    Chef::Log.info "#{ @new_resource } doesn't exists - can't delete."
  end
end

def load_current_resource
  @current_resource = Chef::Resource::EtckeeperGitRemote.new(@new_resource.name)
  @current_resource.directory(@new_resource.directory)
  @current_resource.host(@new_resource.host)
  @current_resource.repository(@new_resource.repository)
  @current_resource.port(@new_resource.port)
  @current_resource.user(@new_resource.user)
  @current_resource.branch(@new_resource.branch)
  @current_resource.sshkey(@new_resource.sshkey)

  url = get_remote_url(
    user: @current_resource.user,
    host: @current_resource.host,
    port: @current_resource.port,
    repository: @current_resource.repository
  )

  @current_resource.exists = (
    remote_exists_with_url?(
      @current_resource.name, url, @current_resource.directory
    ) &&
    branch_exists?(@current_resource.branch, @current_resource.directory) &&
    ssh_key_exists?(@current_resource.name, @current_resource.sshkey) &&
    ssh_config_exists?(@current_resource.host) &&
    remote_used?(@current_resource.name)
  )
end

private

def remote_exists?(remote, directory)
  git_cfg = "git --git-dir=#{directory}/.git config"
  cmd = Mixlib::ShellOut.new(
    "#{git_cfg} --get remote.#{remote}.url"
  )
  cmd.run_command
  cmd.exitstatus == 0
end

def remote_exists_with_url?(remote, url, directory)
  git_cfg = "git --git-dir=#{directory}/.git config"
  cmd = Mixlib::ShellOut.new(
    "#{git_cfg} --get remote.#{remote}.url #{url}"
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

def ssh_key_exists?(name, key)
  keyfile = get_key_filename(name)
  ::File.exist?(keyfile) && ::IO.read(keyfile) == key
end

def ssh_config_exists?(host)
  cfgfile = '/root/.ssh/config'
  ::File.exist?(cfgfile) && ::IO.read(cfgfile).match(
    /^Host #{Regexp.escape(host)}/
  )
end

def remote_used?(name)
  node['etckeeper_git']['remotes'].split(/\s+/).include? name
end

def add_ssh_key
  file get_key_filename(new_resource.name) do
    owner 'root'
    group 'root'
    mode '0600'
    content new_resource.sshkey
    action :create
  end
end

def add_git_remote
  url = get_remote_url(
    user: current_resource.user,
    host: current_resource.host,
    port: current_resource.port,
    repository: current_resource.repository
  )
  remote = current_resource.name
  return if remote_exists_with_url?(remote, url, new_resource.directory)
  git_cfg = "git --git-dir=#{new_resource.directory}/.git config"
  cmd = Mixlib::ShellOut.new(
    "#{git_cfg} --add remote.#{remote}.url #{url}"
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

def get_key_filename(name)
  "/root/.ssh/id_#{name}"
end

def get_remote_url(urlparts = {})
  user = urlparts.fetch(:user, 'git')
  host = urlparts.fetch(:host)
  port = urlparts.fetch(:port, 22)
  repository = urlparts.fetch(:repository)
  host += ":#{port}" if port != 22
  "ssh://#{user}@#{host}/#{repository}"
end

def set_ssh_config
  keyfile = get_key_filename(new_resource.name)
  port = new_resource.port
  host = new_resource.host
  user = new_resource.user

  ssh_config new_resource.name do
    user 'root'
    host host
    options user: user,
            Port: port,
            StrictHostKeyChecking: 'no',
            IdentityFile: keyfile
    action :add
  end
end

def use_remote
  return if remote_used?(new_resource.name)
  node.set['etckeeper_git']['remotes'] =
    node['etckeeper_git']['remotes'].split(/\s+/)
                                    .push(new_resource.name)
                                    .join(' ')
end

def delete_ssh_key
  file get_key_filename(new_resource.name) do
    action :delete
  end
end

def delete_git_remote
  remote = new_resource.name
  return unless remote_exists(remote, new_resource.directory)
  git_cfg = "git --git-dir=#{new_resource.directory}/.git config"
  cmd = Mixlib::ShellOut.new(
    "#{git_cfg} remote remove #{remote}"
  )
  cmd.run_command
  cmd.exitstatus == 0
end

def delete_git_remote_branch
  return unless branch_exists?(new_resource.branch, new_resource.directory)
  git_cfg = "git --git-dir=#{new_resource.directory}/.git config"
  cmd = Mixlib::ShellOut.new(
    "#{git_cfg} --unset branch.master.remote #{new_resource.branch}"
  )
  cmd.run_command
  cmd.exitstatus == 0
end

def delete_ssh_config
  ssh_config new_resource.name do
    user 'root'
    host new_resource.host
    action :remove
  end
end

def dont_use_remote
  return unless remote_used?(new_resource.name)
  node.set['etckeeper_git']['remotes'] =
    node['etckeeper_git']['remotes'].split(/\s+/)
                                    .reject { |r| r == new_resource.name }
                                    .join(' ')
end
