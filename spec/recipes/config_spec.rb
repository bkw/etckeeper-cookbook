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
      attr = chef_run.node['etckeeper']
      expect(chef_run).to create_etckeeper_git_remote(//)
        .with(url: "#{attr['git_host']}:#{attr['git_repo']}")
        .with(branch: attr['git_branch'])
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
      let(:remote_check) { double('shellout remote check') }
      let(:remote_add)   { double('shellout remote add') }
      let(:branch_check) { double('shellout branch check') }

      before do
        git_cfg = 'git --git-dir=/etc/.git config'

        allow(Mixlib::ShellOut).to receive(:new)
          .and_call_original

        allow(Mixlib::ShellOut).to receive(:new)
          .with("#{git_cfg} --get remote.origin.url github.com:etckeeper")
          .and_return(remote_check)
        allow(remote_check).to receive(:run_command)
        allow(remote_check).to receive(:exitstatus).and_return(1)

        allow(Mixlib::ShellOut).to receive(:new)
          .with("#{git_cfg} --add remote.origin.url github.com:etckeeper")
          .and_return(remote_add)
        allow(remote_add).to receive(:run_command)
        allow(remote_add).to receive(:exitstatus).and_return(0)

        allow(Mixlib::ShellOut).to receive(:new)
          .with("#{git_cfg} --get branch.master.remote fauxhai.local")
          .and_return(branch_check)
        allow(branch_check).to receive(:run_command)
        allow(branch_check).to receive(:exitstatus).and_return(1)

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
        expect(remote_add).not_to receive(:run_command)
      end
    end

    context 'with set git remote' do
      let(:remote_check) { double('shellout remote check') }
      let(:remote_add)   { double('shellout remote add') }
      let(:branch_check) { double('shellout branch check') }

      before do
        git_cfg = 'git --git-dir=/etc/.git config'

        allow(Mixlib::ShellOut).to receive(:new)
          .and_call_original

        allow(Mixlib::ShellOut).to receive(:new)
          .with("#{git_cfg} --get remote.origin.url github.com:etckeeper")
          .and_return(remote_check)
        allow(remote_check).to receive(:run_command)
        allow(remote_check).to receive(:exitstatus)
          .and_return(1)

        allow(Mixlib::ShellOut).to receive(:new)
          .with("#{git_cfg} --add remote.origin.url github.com:etckeeper")
          .and_return(remote_add)
        allow(remote_add).to receive(:run_command)
        allow(remote_add).to receive(:exitstatus).and_return(0)

        allow(Mixlib::ShellOut).to receive(:new)
          .with("#{git_cfg} --get branch.master.remote fauxhai.local")
          .and_return(branch_check)
        allow(branch_check).to receive(:run_command)
        allow(branch_check).to receive(:exitstatus).and_return(0)

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
        expect(remote_add).not_to receive(:run_command)
      end
    end

    context 'without set remote git branch' do
      let(:remote_check) { double('shellout remote check') }
      let(:branch_check) { double('shellout branch check') }
      let(:branch_set)   { double('shellout branch set') }
      before do
        git_cfg = 'git --git-dir=/etc/.git config'

        allow(Mixlib::ShellOut).to receive(:new)
          .and_call_original

        allow(Mixlib::ShellOut).to receive(:new)
          .with("#{git_cfg} --get remote.origin.url github.com:etckeeper")
          .and_return(remote_check)
        allow(remote_check).to receive(:run_command)
        allow(remote_check).to receive(:exitstatus)
          .and_return(0)

        allow(Mixlib::ShellOut).to receive(:new)
          .with("#{git_cfg} --get branch.master.remote fauxhai.local")
          .and_return(branch_check)
        allow(branch_check).to receive(:run_command)
        allow(branch_check).to receive(:exitstatus).and_return(1)

        allow(Mixlib::ShellOut).to receive(:new)
          .with("#{git_cfg} --set branch.master.remote fauxhai.local")
          .and_return(branch_set)
        allow(branch_set).to receive(:run_command)
        allow(branch_set).to receive(:exitstatus).and_return(0)

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
        expect(branch_set).not_to receive(:run_command)
      end
    end

    context 'with existing remote git branch' do
      let(:remote_check) { double('shellout remote check') }
      let(:branch_check) { double('shellout branch check') }
      let(:branch_set)   { double('shellout branch set') }
      before do
        git_cfg = 'git --git-dir=/etc/.git config'

        allow(Mixlib::ShellOut).to receive(:new)
          .and_call_original
        allow(Mixlib::ShellOut).to receive(:new)
          .with("#{git_cfg} --get remote.origin.url github.com:etckeeper")
          .and_return(remote_check)
        allow(remote_check).to receive(:run_command)
        allow(remote_check).to receive(:exitstatus)
          .and_return(0)

        allow(Mixlib::ShellOut).to receive(:new)
          .with("#{git_cfg} --get branch.master.remote fauxhai.local")
          .and_return(branch_check)
        allow(branch_check).to receive(:run_command)
        allow(branch_check).to receive(:exitstatus).and_return(0)

        allow(Mixlib::ShellOut).to receive(:new)
          .with("#{git_cfg} --set branch.master.remote fauxhai.local")
          .and_return(branch_set)
        allow(branch_set).to receive(:run_command)
        allow(branch_set).to receive(:exitstatus).and_return(0)

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
        expect(branch_set).not_to receive(:run_command)
      end
    end
  end
end
