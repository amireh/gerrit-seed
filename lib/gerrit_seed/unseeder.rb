module GerritSeed
  class Unseeder
    attr_reader :gerrit, :git

    def initialize(gerrit:, git:)
      @gerrit = gerrit
      @git = git
    end

    def apply(directive_list)
      directives = directive_list.reduce({}) do |acc, item|
        item.keys.each do |key|
          acc[key.to_sym] ||= []
          acc[key.to_sym] << item[key].transform_keys(&:to_sym)
        end

        acc
      end

      directives[:project].tap do |projects|
        projects.each(&gerrit.method(:delete_project))
        projects.each(&git.method(:rm_rf))
      end

      directives[:user].reject do |user|
        user[:username] == gerrit.user
      end.each(&gerrit.method(:delete_user))
    end
  end
end
