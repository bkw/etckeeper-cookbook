# encoding: UTF-8

require 'spec_helper'

describe 'etckeeper_git_test::default' do

  context 'new remote' do
    let(:remote_add)   { double('shellout remote add') }
    let(:remote_check) { double('shellout remote check') }
    let(:branch_check) { double('shellout branch check') }
    let(:branch_set)   { double('shellout branch set') }

    before do
      git_cfg = 'git --git-dir=/usr/local/etc/.git config'
      url = 'ssh://gituser@test1.example.com:2222/some/repo'
      branch = 'production'

      # stub setting remote
      allow(Mixlib::ShellOut).to receive(:new)
        .with("#{git_cfg} --add remote.remote1.url #{url}")
        .and_return(remote_add)
      allow(remote_add).to receive(:run_command)
        .and_return(true)
      allow(remote_add).to receive(:exitstatus)
        .and_return(0) # success

      # stub check for exisiting remote
      allow(Mixlib::ShellOut).to receive(:new)
        .with("#{git_cfg} --get remote.remote1.url #{url}")
        .and_return(remote_check)
      allow(remote_check).to receive(:run_command)
      allow(remote_check).to receive(:exitstatus)
        .and_return(1) # remote does not exist

      # stub checking for existing branch
      allow(Mixlib::ShellOut).to receive(:new)
        .with("#{git_cfg} --get branch.master.remote #{branch}")
        .and_return(branch_check)
      allow(branch_check).to receive(:run_command)
      allow(branch_check).to receive(:exitstatus)
        .and_return(1) # branch does not exist

      # stub setting the branch
      allow(Mixlib::ShellOut).to receive(:new)
        .with("#{git_cfg} --set branch.master.remote #{branch}")
        .and_return(branch_set)
      allow(branch_set).to receive(:run_command)
      allow(branch_set).to receive(:exitstatus).and_return(0)
    end

    let(:chef_run) do
      ChefSpec::Runner.new(step_into: ['etckeeper_git_remote']) do |node|
        node.set['etckeeper_git']['remotes'] = 'existing_remote'
      end.converge(described_recipe)
    end

    it 'creates the resource' do
      expect(chef_run).to create_etckeeper_git_remote('remote1')
    end

    it 'adds the ssh key for remote1' do
      expect(chef_run).to create_file('/root/.ssh/id_remote1')
        .with(owner: 'root')
        .with(group: 'root')
        .with(mode: '0600')
        .with(content: 'not-really-a-key')
    end

    it 'configures ssh config to use the key for remote1' do
      expect(chef_run).to add_ssh_config('remote1')
        .with(user: 'root')
        .with(host: 'test1.example.com')
        .with(
          options: {
            user: 'gituser',
            Port: 2222,
            StrictHostKeyChecking: 'no',
            IdentityFile: '/root/.ssh/id_remote1'
          }
        )
    end

    it 'adds the git remote to the git config' do
      expect(remote_add).to receive(:run_command)
      chef_run
    end

    it 'sets the branch for remote1' do
      expect(branch_set).to receive(:run_command)
      chef_run
    end

    it 'adds the remote to the attribute' do
      expect(chef_run.node['etckeeper_git']['remotes']).to eq(
        'existing_remote remote1'
      )
    end
  end
end
