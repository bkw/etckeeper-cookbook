# encoding: UTF-8

require 'spec_helper'

describe 'etckeeper::config' do

  cached(:chef_run) do
    ChefSpec::Runner.new.converge(described_recipe)
  end

  it 'creates the etckeeper config file' do
    expect(chef_run).to render_file('/etc/etckeeper/etckeeper.conf')
  end

  it 'creates the etckeeper cron job by default' do
    expect(chef_run).to create_template('/etc/cron.daily/etckeeper')
      .with(owner: 'root')
      .with(mode: '0755')
    expect(chef_run).to render_file('/etc/cron.daily/etckeeper')
      .with_content(/etckeeper commit "daily autocommit"/)
  end

  context 'with attribute daily_auto_commits set to false' do
    cached(:chef_run) do
      ChefSpec::Runner.new do |node|
        node.set['etckeeper']['daily_auto_commits'] = false
      end.converge(described_recipe)
    end

    it 'does not install the etckeeper cron job' do
      expect(chef_run).not_to render_file('/etc/cron.daily/etckeeper')
    end
  end

  context 'with attribute use_remote' do
    before do
      stub_command('git config --get remote.origin.url')
        .and_return(false)
      stub_command('git config --get branch.master.remote')
        .and_return(false)
    end

    cached(:chef_run) do
      ChefSpec::Runner.new do |node|
        node.set['etckeeper']['use_remote'] = true
      end.converge(described_recipe)
    end

    it 'creates directory /root/.ssh' do
      expect(chef_run).to create_directory('/root/.ssh')
        .with(owner: 'root')
        .with(group: 'root')
        .with(mode: '0700')
    end

    it 'creates the etckeeper ssh key' do
      expect(chef_run).to create_cookbook_file_if_missing(
        '/root/.ssh/etckeeper_key'
      ).with(mode: '0600')
    end

    it 'creates /root/.ssh/config' do
      expect(chef_run).to create_template('/root/.ssh/config')
        .with(mode: '0600')
      expect(chef_run).to render_file('/root/.ssh/config')
        .with_content(/^Host #{chef_run.node['etckeeper']['git_host']}$/)
        .with_content(/^\s+user\s+git$/)
        .with_content(/^\s+Port\s+#{chef_run.node['etckeeper']['git_port']}$/)
        .with_content(/^\s+StrictHostKeyChecking\s+no$/)
        .with_content(%r{^\s+IdentityFile\s+/root/.ssh/etckeeper_key$})
    end

    context 'without set git remote' do
      it 'adds the configured origin' do
        host = chef_run.node['etckeeper']['git_host']
        repo = chef_run.node['etckeeper']['git_repo']
        expect(chef_run).to run_execute("git remote add origin #{host}:#{repo}")
      end
    end

    context 'with set git remote' do
      before do
        stub_command('git config --get remote.origin.url')
          .and_return('something')
        stub_command('git config --get branch.master.remote')
          .and_return('something')
      end

      cached(:chef_run) do
        ChefSpec::Runner.new do |node|
          node.set['etckeeper']['use_remote'] = true
        end.converge(described_recipe)
      end

      it 'does not change the configured origin' do
        host = chef_run.node['etckeeper']['git_host']
        repo = chef_run.node['etckeeper']['git_repo']
        expect(chef_run).not_to run_execute(
          "git remote add origin #{host}:#{repo}"
        )
      end
    end

    context 'without set remote git branch' do
      before do
        stub_command('git config --get remote.origin.url')
          .and_return('something')
        stub_command('git config --get branch.master.remote')
          .and_return(false)
      end

      cached(:chef_run) do
        ChefSpec::Runner.new do |node|
          node.set['etckeeper']['use_remote'] = true
        end.converge(described_recipe)
      end

      it 'sets the branch' do
        branch = chef_run.node['etckeeper']['git_branch']
        expect(chef_run).to run_execute(
          "git push --set-upstream origin #{branch}"
        )
      end
    end

    context 'with existing remote git branch' do
      before do
        stub_command('git config --get remote.origin.url')
          .and_return('something')
        stub_command('git config --get branch.master.remote')
          .and_return('something')
      end

      cached(:chef_run) do
        ChefSpec::Runner.new do |node|
          node.set['etckeeper']['use_remote'] = true
        end.converge(described_recipe)
      end

      it 'does not set the branch' do
        branch = chef_run.node['etckeeper']['git_branch']
        expect(chef_run).not_to run_execute(
          "git push --set-upstream origin #{branch}"
        )
      end
    end
  end
end