require 'open3'

RSpec.describe 'Ruby 3 compatibility' do
  around do |example|
    Dir.mktmpdir('wordmove-compatibility-') do |dir|
      @dir = dir
      example.run
    end
  end

  let(:path) { File.join(@dir, 'movefile.yml') }
  let(:movefile) { Wordmove::Movefile.new('movefile.yml', @dir) }

  before do
    File.write(path, <<~YAML)
      global:
        sql_adapter: wpcli
      local:
        vhost: http://local.test
        wordpress_path: #{@dir}/local
        database: &database
          name: fixture
          user: fixture
          password: ''
          host: localhost
      staging:
        vhost: https://example.invalid
        wordpress_path: /srv/fixture
        database: *database
        ssh:
          host: example.invalid
          user: fixture
    YAML
  end

  it 'boots the CLI in a fresh process without the io-wait deprecation warning' do
    stdout, stderr, status = Open3.capture3(RbConfig.ruby, '-Ilib', 'exe/wordmove', '--version')
    expect(status.success?).to be(true), stderr
    expect(stdout).to include(Wordmove::VERSION)
    expect(stderr).not_to include('io-wait gem is deprecated')
  end

  it 'loads YAML aliases and selects the remote environment' do
    expect(movefile.fetch(false).dig(:staging, :database, :name)).to eq('fixture')
    expect(movefile.environment({})).to eq(:staging)
  end

  it 'rejects arbitrary Ruby objects in Movefiles' do
    File.write(path, "local: !ruby/object:Object {}\n")
    expect { movefile.fetch(false) }.to raise_error(Psych::DisallowedClass)
  end

  it 'validates all bundled schemas using the current YAML parser' do
    doctor = Wordmove::Doctor::Movefile.new('movefile.yml', @dir)
    %i[global local staging].each do |section|
      validator = doctor.send(:validator_for, section)
      expect(validator.validate(doctor.contents.fetch(section).deep_stringify_keys)).to be_empty
    end
  end

  it 'still rejects invalid data with the bundled schema' do
    doctor = Wordmove::Doctor::Movefile.new('movefile.yml', @dir)
    validator = doctor.send(:validator_for, :global)
    expect(validator.validate({}).map(&:message)).to include(/sql_adapter/)
  end

  it 'suggests a correction for a mistyped command with current DidYouMean' do
    error = Thor::UndefinedCommandError.new('pus', %w[push pull], nil)
    expect(error.corrections.join).to include('push')
  end

  it 'constructs WP-CLI search-replace commands from wp-cli.yml' do
    File.write(File.join(@dir, 'wp-cli.yml'), "path: #{@dir}\n")
    data = movefile.fetch(false)
    adapter = Wordmove::SqlAdapter::Wpcli.new(data[:local], data[:staging], :vhost, @dir)
    allow(adapter).to receive(:wp_in_path?).and_return(true)
    expect(adapter.command).to include("--path=#{@dir}")
    expect(adapter.command).to include('http://local.test https://example.invalid')
  end

  it 'preserves database push and pull flow without executing remote or database operations' do
    expect(Net::SSH).not_to receive(:start)
    Dir.chdir(@dir) do
      deployer = Wordmove::Deployer::Base.deployer_for(
        config: 'movefile.yml', environment: 'staging'
      )
      %i[remote_run remote_get remote_put remote_delete remote_get_directory
         remote_put_directory run local_delete].each do |method|
        allow(deployer).to receive(method).and_return(true)
      end
      allow(deployer).to receive(:wpcli_search_replace)
        .and_return('wp search-replace fixture fixture')

      deployer.send(:push_db)
      expect(deployer).to have_received(:remote_put)
      expect(deployer).to have_received(:remote_run).with(a_string_starting_with('mysql '))

      expect(deployer).to have_received(:remote_get).once
      deployer.send(:pull_db)
      expect(deployer).to have_received(:remote_get).twice
      expect(deployer).to have_received(:run).with(a_string_starting_with('mysql ')).twice
    end
  end

  it 'preserves serialized SQL lengths during a URL and path round trip' do
    local = { vhost: 'http://local.test', wordpress_path: '/local/site' }
    remote = { vhost: 'https://example.invalid', wordpress_path: '/srv/fixture' }
    original = 'http://local.test/path'
    replaced = 'https://example.invalid/path'
    sql = File.join(@dir, 'fixture.sql')
    contents = %(s:#{original.bytesize}:"#{original}"; /local/site/wp-content)
    File.write(sql, contents)
    Wordmove::SqlAdapter::Default.new(sql, local, remote).adapt!
    expect(File.read(sql)).to eq(%(s:#{replaced.bytesize}:"#{replaced}"; /srv/fixture/wp-content))
    Wordmove::SqlAdapter::Default.new(sql, remote, local).adapt!
    expect(File.read(sql)).to eq(contents)
  end
end
