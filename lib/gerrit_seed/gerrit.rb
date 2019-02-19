module GerritSeed
  class Gerrit
    attr_reader :host, :log, :port, :shell, :user

    def initialize(host:, log:, port:, user:)
      @host = host
      @log = log
      @port = port
      @shell = Shell.new
      @user = user
    end

    def create_project(name:, **)
      unless exec('gerrit ls-projects').match(name)
        exec('gerrit create-project',
          name,
          '--change-id', 'TRUE',
          '--empty-commit',
          '--require-change-id'
        )

        log.ok("project: #{name}")
      end
    end

    def delete_project(name:, **)
      if has_project?(name)
        begin
          exec('delete-project', 'delete', '--force', '--yes-really-delete', name)
        rescue Shell::CommandError => e
          raise if has_project?(name) || e.output.strip != 'fatal: internal server error'
        end

        log.ok("project: #{name}")
      end
    end

    def has_project?(name)
      exec('gerrit ls-projects').lines.map(&:strip).include?(name)
    end

    def install_plugin(name:, url:)
      unless JSON.parse(exec('gerrit plugin ls --format JSON')).key?(name.to_s)
        exec('gerrit', 'plugin', 'install', "'#{url}'")
        log.ok("plugin: #{name}")
      end
    end

    def create_user(email:, group:, full_name:, username:, ssh_key:, **)
      begin
        exec('gerrit create-account', '--group', sq(group), username)
        log.ok("user: #{username}")
      rescue Shell::CommandError => e
        raise unless e.output.strip == "fatal: username '#{username}' already exists"
      end

      exec(
        'gerrit', 'set-account',
          '--active',
          '--full-name',    sq(full_name),
          '--add-email',    sq(email),
          '--add-ssh-key',  '-',
          '--preferred-email', sq(email),
          username,
        stdin: File.read(File.expand_path(ssh_key))
      )
    end

    def delete_user(username:, **)
      exec('gerrit set-account', '--inactive', username)
      log.ok("user: #{username}")
    rescue Shell::CommandError => e
      raise unless e.output.strip == 'fatal: account not active'
    end

    def create_change(change, changes:, git:, users:, **)
      branch_name = branch_name_of(change[:name])
      parent_change = changes.detect do |other_change|
        other_change[:project] == change[:project] &&
        other_change[:name].start_with?(change[:parent])
      end

      parent_branch_name = if parent_change
        branch_name_of(parent_change[:name])
      else
        change[:parent]
      end

      author = users.detect { |x| x[:username] == change[:author] }

      unless author
        fail "Author '#{change[:author]}' for change '#{change[:name]}' could not be found"
      end

      git.checkout(
        branch: branch_name,
        commit: parent_branch_name,
      )

      if change[:files]
        change[:files].map do |file| File.expand_path(file, git.dir) end.each do |file|
          FileUtils.mkdir_p(File.dirname(file)) unless File.exist?(File.dirname(file))
          FileUtils.touch(file)
        end

        git.shell.("git add .")
      else
        git.shell.("touch #{branch_name}.in")
        git.shell.("git add #{branch_name}.in")
      end

      git.commit(
        author: author[:full_name],
        email: author[:email],
        subject: change[:name],
      )

      unless change_submitted?(change)
        git.push(
          user: author[:username],
          reviewers: %w[admin] + users.map { |x| x[:username] }
        )

        log.ok("change: #{change[:project]} - #{change[:name]}")
      end
    end

    private

    def branch_name_of(string)
      string.gsub(/\W+/, '_').gsub(/\_+/, '_').gsub(/^_|_$/, '').downcase
    end

    def change_submitted?(change)
      exec('gerrit query --format json -- status:open').lines.any? do |line|
        JSON.parse(line)['subject'] == change[:name]
      end
    end

    def exec(*cmd, **kwargs)
      shell.(
        'ssh', '-p', port.to_s, "#{user}@#{host}",
        *cmd,
        **kwargs
      )
    end

    def sq(word)
      "'#{word}'"
    end
  end
end
