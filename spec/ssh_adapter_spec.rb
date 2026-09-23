require 'json'
require 'open3'

RSpec.describe Wordmove::SSHAdapter do
  let(:adapter) { described_class.new(host: 'server', user: 'deploy', port: 2222) }

  def capture_command(copier)
    command = nil
    allow(copier).to receive(:system) do |value|
      command = Shellwords.split(value)
      true
    end
    yield
    command
  end

  it 'places the host in the pull source and keeps SSH options in the remote shell' do
    Dir.mktmpdir do |dir|
      command = capture_command(adapter) { adapter.get_directory('/site path', dir) }
      expect(command.last(2)).to eq(['server:/site path/', dir])
      expect(Shellwords.split(command[command.index('-e') + 1]))
        .to eq(['ssh', '-p', '2222', '-l', 'deploy'])
    end
  end

  it 'places the host in the push destination and preserves filters and dry-run' do
    copier = described_class.new(host: 'server', rsync_options: '--dry-run --human-readable')
    command = capture_command(copier) do
      copier.put_directory('/local path', '/site path', ['/*'], ['/wp-content/'])
    end
    expect(command.last(2)).to eq(['/local path/', 'server:/site path'])
    expect(command).to include('--dry-run', '--human-readable', '--delete')
    expect(command[command.index('--include') + 1]).to eq('/wp-content/')
    expect(command[command.index('--exclude') + 1]).to eq('/*')
  end

  it 'keeps the gateway destination before the final SSH command' do
    copier = described_class.new(host: 'server', user: 'deploy',
                                 gateway: { host: 'jump', user: 'jump-user', port: 2223 })
    command = capture_command(copier) { copier.put_directory('/local', '/site') }
    expect(Shellwords.split(command[command.index('-e') + 1]))
      .to eq(['ssh', '-p', '2223', '-l', 'jump-user', 'jump', 'ssh', '-l', 'deploy'])
  end

  it 'brackets an IPv6 remote host' do
    copier = described_class.new(host: '::1')
    command = capture_command(copier) { copier.put_directory('/local', '/site') }
    expect(command.last).to eq('[::1]:/site')
  end

  it 'reports a failed command without including credentials in the exception' do
    expect { adapter.send(:run, "#{RbConfig.ruby} -e 'exit 23' # secret") }
      .to raise_error(Wordmove::ShellCommandError, /rsync failed \(exit 23\)/)
  end

  it 'reports a command that cannot start' do
    allow(adapter).to receive(:system).and_return(nil)
    expect { adapter.send(:run, 'missing-rsync') }
      .to raise_error(Wordmove::ShellCommandError, 'rsync could not be started')
  end

  it 'does not log an encoded SSH password' do
    copier = described_class.new(host: 'server', password: "a secret'with quotes")
    logger = double(:logger)
    copier.logger = logger
    expect(logger).to receive(:info).with(include('[SSH command with password redacted]'))
    command = capture_command(copier) { copier.put_directory('/local', '/site') }
    expect(command[command.index('-e') + 1]).to include("'a secret''with quotes'")
  end

  context 'using the installed rsync with a local SSH substitute' do
    around do |example|
      Dir.mktmpdir('wordmove-rsync-') do |dir|
        @dir = dir
        @source = File.join(dir, 'source files')
        @destination = File.join(dir, 'destination files')
        FileUtils.mkdir_p([@source, @destination])
        File.write(File.join(@source, "test 'file.txt"), 'transfer contents')
        File.write(File.join(@source, 'excluded.txt'), 'excluded')
        File.write(File.join(@destination, 'obsolete.txt'), 'obsolete')
        File.write(File.join(dir, 'ssh'), <<~RUBY)
          #!#{RbConfig.ruby}
          require 'json'
          File.write(#{File.join(dir, 'ssh-args.json').inspect}, JSON.generate(ARGV))
          ARGV.shift(2) while %w[-p -l].include?(ARGV.first)
          abort 'Unexpected remote host' unless ARGV.shift == 'server'
          exec('/bin/sh', '-c', ARGV.join(' '))
        RUBY
        File.chmod(0o700, File.join(dir, 'ssh'))
        original_path = ENV.fetch('PATH')
        begin
          ENV['PATH'] = "#{dir}:#{original_path}"
          silence_stream($stdout) { example.run }
        ensure
          ENV['PATH'] = original_path
        end
      end
    end

    it 'pulls real file contents and applies exclusions and deletion in temporary directories' do
      adapter.get_directory(@source, @destination, ['excluded.txt'])
      expect(File.read(File.join(@destination, "test 'file.txt"))).to eq('transfer contents')
      expect(File).not_to exist(File.join(@destination, 'excluded.txt'))
      expect(File).not_to exist(File.join(@destination, 'obsolete.txt'))
    end

    it 'pushes real file contents to a temporary directory' do
      adapter.put_directory(@source, @destination)
      expect(File.read(File.join(@destination, "test 'file.txt"))).to eq('transfer contents')
    end

    it 'does not transfer or delete files during a simulation' do
      copier = described_class.new(host: 'server', rsync_options: '--dry-run')
      copier.get_directory(@source, @destination)
      copier.put_directory(@source, @destination)
      expect(Dir.children(@destination)).to eq(['obsolete.txt'])
      expect(File.read(File.join(@destination, 'obsolete.txt'))).to eq('obsolete')
    end

    it 'preserves spaces and quotes in SSH arguments through rsync parsing' do
      copier = described_class.new(host: 'server', user: "user with 'quote")
      copier.get_directory(@source, @destination)
      args = JSON.parse(File.read(File.join(@dir, 'ssh-args.json')))
      expect(args.first(3)).to eq(['-l', "user with 'quote", 'server'])
    end

    it 'raises when the remote shell fails, including during a simulation' do
      File.write(File.join(@dir, 'ssh'), "#!/bin/sh\nexit 7\n")
      copier = described_class.new(host: 'server', rsync_options: '--dry-run')
      silence_stream($stderr) do
        expect { copier.get_directory(@source, @destination) }
          .to raise_error(Wordmove::ShellCommandError, /rsync failed \(exit \d+\)/)
      end
      expect(Dir.children(@destination)).to eq(['obsolete.txt'])
    end

    it 'returns a failing CLI exit status for MoveDock when a transfer fails' do
      File.write(File.join(@dir, 'ssh'), "#!/bin/sh\nexit 7\n")
      config = YAML.load_file(fixture_path_for('movefiles/multi_environments'))
      config['local']['wordpress_path'] = @destination
      config['staging']['wordpress_path'] = @source
      config['staging']['ssh'] = { 'host' => 'server' }
      movefile = File.join(@dir, 'movefile.yml')
      File.write(movefile, YAML.dump(config))
      _, stderr, status = Open3.capture3(
        RbConfig.ruby, '-I', File.expand_path('../lib', __dir__),
        File.expand_path('../exe/wordmove', __dir__),
        'pull', '--themes', '--simulate', '-e', 'staging', '-c', movefile
      )
      expect(status.exitstatus).to eq(1)
      expect(stderr).to include('Wordmove::ShellCommandError', 'rsync failed')
      expect(Dir.children(@destination)).to eq(['obsolete.txt'])
    end
  end
end
