module Wordmove
  # Compatibility with rsync clients that require a host in remote paths.
  # Keep Photocopier's SCP and Net::SSH operations for database transfers.
  class SSHAdapter < Photocopier::SSH
    def get_directory(remote_path, local_path, exclude = [], includes = [])
      FileUtils.mkdir_p(local_path)
      rsync remote_location("#{remote_path.to_s.delete_suffix('/')}/"), local_path,
            exclude, includes
    end

    def put_directory(local_path, remote_path, exclude = [], includes = [])
      rsync "#{local_path.to_s.delete_suffix('/')}/", remote_location(remote_path),
            exclude, includes
    end

    private

    def remote_location(path)
      host = options.fetch(:host)
      host = "[#{host}]" if host.include?(':') && !host.start_with?('[')
      "#{host}:#{path}"
    end

    def rsync_command
      super.tap { |command| command[command.index('-e') + 1] = Shellwords.escape(rsh_arguments) }
    end

    def rsh_arguments
      arguments = gateway_options ? ssh_arguments(gateway_options, destination: true) : []
      arguments.concat(ssh_arguments(options))
      # rsync parses -e itself: backslash escaping is not supported here.
      arguments.map { |argument| "'#{argument.to_s.gsub("'", "''")}'" }.join(' ')
    end

    def ssh_arguments(opts, destination: false)
      arguments = opts[:password] ? ['sshpass', '-p', opts[:password]] : []
      arguments << 'ssh'
      arguments.concat(['-p', opts[:port]]) if opts[:port].present?
      arguments.concat(['-l', opts[:user]]) if opts[:user].present?
      arguments << opts.fetch(:host) if destination
      arguments
    end

    def run(command)
      logger.info(log_command(command)) if logger.present?
      result = system(command)
      return true if result

      raise ShellCommandError, 'rsync could not be started' if result.nil?

      status = $CHILD_STATUS
      detail = status&.signaled? ? "signal #{status.termsig}" : "exit #{status&.exitstatus}"
      raise ShellCommandError, "rsync failed (#{detail}); see the transfer log above"
    end

    def log_command(command)
      return command unless options[:password] || gateway_options&.dig(:password)

      command.sub(Shellwords.escape(rsh_arguments), '[SSH command with password redacted]')
    end
  end
end
