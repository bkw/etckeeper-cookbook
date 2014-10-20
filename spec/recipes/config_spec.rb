# encoding: UTF-8

require 'spec_helper'

describe 'etckeeper::config' do

  git_cmd = 'git --git-dir=/etc/.git'

  before do
    stub_command(
      "#{git_cmd} config --get user.email | fgrep -q 'root@fauxhai.local'"
    ).and_return(true)
  end

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

  it 'does not create a etckeeper_git_remote resource by default' do
    expect(chef_run).not_to create_etckeeper_git_remote(//)
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

  context 'without existing git repository' do
    before do
      allow(File).to receive(:exist?)
        .and_call_original
      allow(File).to receive(:exist?)
        .with('/etc/.git/config')
        .and_return(false)
    end

    cached(:chef_run) { ChefSpec::Runner.new.converge(described_recipe) }

    it 'runs "etckeeper init"' do
      expect(chef_run).to run_execute('etckeeper init')
    end
  end

  context 'with existing git repository' do
    before do
      allow(File).to receive(:exist?)
        .and_call_original
      allow(File).to receive(:exist?)
        .with('/etc/.git/config')
        .and_return(true)
    end

    cached(:chef_run) do
      ChefSpec::Runner.new(
        step_into: ['etckeeper_git_remote']
      ).converge(described_recipe)
    end

    it 'does not run "etckeeper init" again' do
      expect(chef_run).not_to run_execute('etckeeper init')
    end
  end

  context 'with attribute use_remote' do
    before do
      stub_command("#{git_cmd} config --get remote.origin.url")
        .and_return(false)
      stub_command("#{git_cmd} config --get branch.master.remote")
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

    it 'creates a etckeeper_git_remote resource' do
      expect(chef_run).to create_etckeeper_git_remote(//)
        .with(url: "#{chef_run.node['etckeeper']['git_host']}:#{chef_run.node['etckeeper']['git_repo']}")
        .with(branch: chef_run.node['etckeeper']['git_branch'])
    end

    context 'without email address in git config' do
      before do
        stub_command(
          "#{git_cmd} config --get user.email | fgrep -q 'x@example.com'"
        ).and_return(false)
      end

      cached(:chef_run) do
        ChefSpec::Runner.new do |node|
          node.set['etckeeper']['git_email'] = 'x@example.com'
        end.converge(described_recipe)
      end

      it 'adds the email to git config' do
        expect(chef_run).to run_execute('etckeeper_set_git_email')
          .with(command: "#{git_cmd} config user.email 'x@example.com'")
      end
    end

    context 'with existing user info in git config' do
      before do
        stub_command(
          "#{git_cmd} config --get user.email | fgrep -q 'x@example.com'"
        ).and_return(true)
      end

      cached(:chef_run) do
        ChefSpec::Runner.new do |node|
          node.set['etckeeper']['git_email'] = 'x@example.com'
        end.converge(described_recipe)
      end

      it 'does not set the email again' do
        expect(chef_run).not_to run_execute('etckeeper_set_git_email')
      end

    end

    context 'without set git remote' do
      before do
        stub_command(
          "#{git_cmd} config --get remote.origin.url github.com:etckeeper"
        ).and_return(false)

        stub_command(
          "#{git_cmd} config --get branch.master.remote fauxhai.local"
        ).and_return(false)

        stub_command(
          "#{git_cmd} config --get user.email | fgrep -q 'x@example.com'"
        ).and_return(false)
      end

      cached(:chef_run) do
        ChefSpec::Runner.new(step_into: ['etckeeper_git_remote']) do |node|
          node.set['etckeeper']['use_remote'] = true
          node.set['etckeeper']['git_email'] = 'x@example.com'
        end.converge(described_recipe)
      end

      it 'adds the configured origin' do
        expect(chef_run).to run_execute(
          'git-add-remote-github.com:etckeeper/fauxhai.local'
        ).with(command: "#{git_cmd} config --add remote.origin.url github.com:etckeeper")
      end
    end

    context 'with set git remote' do
      before do
        stub_command(
          "#{git_cmd} config --get remote.origin.url github.com:etckeeper"
        ).and_return(true)

        stub_command(
          "#{git_cmd} config --get branch.master.remote fauxhai.local"
        ).and_return(false)

        stub_command(
          "#{git_cmd} config --get user.email | fgrep -q 'x@example.com'"
        ).and_return('something')
      end

      cached(:chef_run) do
        ChefSpec::Runner.new(step_into: ['etckeeper_git_remote']) do |node|
          node.set['etckeeper']['use_remote'] = true
        end.converge(described_recipe)
      end

      it 'does not change the configured origin' do
        expect(chef_run).not_to run_execute(
          "#{git_cmd}-add-remote-github.com:etckeeper/fauxhai.local"
        )
      end
    end

    context 'without set remote git branch' do
      before do
        stub_command(
          "#{git_cmd} config --get remote.origin.url github.com:etckeeper"
        ).and_return(true)

        stub_command(
          "#{git_cmd} config --get branch.master.remote fauxhai.local"
        ).and_return(false)

        stub_command(
          "#{git_cmd} config --get user.email | fgrep -q 'x@example.com'"
        ).and_return(true)
      end

      cached(:chef_run) do
        ChefSpec::Runner.new(step_into: ['etckeeper_git_remote']) do |node|
          node.set['etckeeper']['use_remote'] = true
        end.converge(described_recipe)
      end

      it 'sets the branch' do
        branch = chef_run.node['etckeeper']['git_branch']
        expect(chef_run).to run_execute("git-set-branch-#{branch}")
          .with(
            command: "#{git_cmd} config --set branch.master.remote #{branch}"
          )
      end
    end

    context 'with existing remote git branch' do
      before do
        stub_command(
          "#{git_cmd} config --get remote.origin.url github.com:etckeeper"
        ).and_return(true)

        stub_command(
          "#{git_cmd} config --get branch.master.remote fauxhai.local"
        ).and_return(true)

        stub_command(
          "#{git_cmd} config --get user.email | fgrep -q 'x@example.com'"
        ).and_return(true)
      end

      cached(:chef_run) do
        ChefSpec::Runner.new(step_into: ['etckeeper_git_remote']) do |node|
          node.set['etckeeper']['use_remote'] = true
        end.converge(described_recipe)
      end

      it 'does not set the branch' do
        branch = chef_run.node['etckeeper']['git_branch']
        expect(chef_run).not_to run_execute("git-set-branch-#{branch}")
      end
    end
  end
end
