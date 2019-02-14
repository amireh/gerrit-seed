require 'open3'

module GerritSeed
  class Shell
    class CommandError < StandardError
      attr_reader :command, :exit_status, :output

      def initialize(message:, command:, exit_status:, output:)
        @command = command
        @exit_status = exit_status
        @output = output

        super(message)
      end
    end

    def initialize(chdir: Dir.pwd)
      @chdir = chdir
    end

    def call(*cmd, stdin: nil, **kwargs)
      buffer, exit_status = Open3.capture2e(*cmd, stdin_data: stdin, chdir: @chdir)

      # buffer = []
      # exit_status = nil
      #
      # Open3.popen2e(*cmd, stdin_data: stdin, chdir: @chdir) do |_stdin, stdout_stderr, wait_thr|
      #   # _stdin.write(stdin) unless stdin.nil?

      #   lines = stdout_stderr.to_a
      #   buffer.concat(lines)

      #   # lines.each do |line|
      #   #   puts line
      #   # end

      #   exit_status = wait_thr.value
      # end

      # buffer = buffer.join

      unless exit_status.success?
        raise CommandError.new(
          message: (
            <<~MESSAGE
              Shell command failed: #{exit_status}:

                  #{cmd}

              Output:

                  #{buffer}

            MESSAGE
          ),
          command: cmd,
          exit_status: exit_status,
          output: buffer
        )
      end

      buffer
    end
  end
end
