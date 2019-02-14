require 'pastel'

module GerritSeed
  class Logger
    def initialize()
    end

    def ok(msg)
      puts Pastel.new.green("✓ #{msg}")
    end
  end
end
