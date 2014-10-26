# encoding: utf-8

include_recipe 'etckeeper_git'

etckeeper_git_remote 'remote1' do
  host 'test2.example.com'
  repository 'some/repo'
  port 2222
  user 'gituser'
  directory '/usr/local/etc'
  branch 'production'
  sshkey 'not-really-a-key'
  action :create
end

etckeeper_git_remote 'remote1' do
  action :delete
end

etckeeper_git_remote 'remote2' do
  action :delete
end
