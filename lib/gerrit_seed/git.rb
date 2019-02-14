module GerritSeed
  class Git
    attr_reader :dir, :host, :port, :log, :name, :shell, :user

    def initialize(dir:, host:, log:, name: nil, port:, user:)
      @dir = dir
      @host = host
      @log = log
      @name = name
      @port = port
      @shell = Shell.new(chdir: dir)
      @user = user
    end

    def clone(name:)
      unless File.exist?(File.join(dir, name))
        shell.("git", "clone", "ssh://#{user}@#{host}:#{port}/#{name}", name)
        shell.(
          'scp',
            '-p',
            '-P', port.to_s,
            "#{user}@#{host}:hooks/commit-msg",
            "#{name}/.git/hooks/"
        )
      end

      self.class.new(
        dir: File.join(dir, name),
        host: host,
        log: log,
        name: name,
        port: port,
        user: user
      )
    end

    def rm_rf(name:)
      if File.exist?(File.join(dir, name))
        FileUtils.rm_rf(File.join(dir, name))
      end
    end

    def checkout(branch:, commit:)
      if available_branches.include?(branch)
        shell.('git', 'checkout', branch)
      else
        shell.('git', 'checkout', '-b', branch, commit)
      end
    end

    def commit(author:, email:, subject:)
      return if shell.('git', 'status', '--short').empty?

      shell.(
        'git',
          "-c", "user.name='#{author}'",
          "-c", "user.email='#{email}'",
          'commit',
            "--author='#{author} <#{email}>'",
            '-m', subject
      )
    end

    def push(user:, reviewers: [])
      fail "name is not set, did you forget to #clone?" if @name.nil?

      reviewers_query = if reviewers.any?
        '%' + reviewers.map { |x| "r=#{x}" }.join(',')
      else
        ''
      end

      shell.(
        'git', 'push',
        "ssh://#{user}@#{host}:#{port}/#{name}",
        'HEAD:refs/for/master' + reviewers_query
      )
    end

    private

    def available_branches
      shell.('git', 'branch', '-l', '--format', '%(refname:short)').lines.map(&:strip)
    end
  end
end
