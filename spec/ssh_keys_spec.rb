require 'open3'

RSpec.describe 'SSH key support' do
  it 'loads an encrypted OpenSSH Ed25519 key and signs with it' do
    Dir.mktmpdir('wordmove-ssh-key-') do |dir|
      path = File.join(dir, 'id_ed25519')
      passphrase = 'temporary-test-passphrase'
      _, stderr, status = Open3.capture3(
        'ssh-keygen', '-q', '-t', 'ed25519', '-N', passphrase, '-f', path
      )
      expect(status.success?).to be(true), stderr

      key = Net::SSH::KeyFactory.load_private_key(path, passphrase, false)
      expect(key.ssh_type).to eq('ssh-ed25519')
      message = 'Wordmove SSH authentication test'
      signature = key.ssh_do_sign(message)
      expect(key.public_key.ssh_do_verify(signature, message)).to be(true)
    end
  end
end
