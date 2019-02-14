module GerritSeed
  class Seeder
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


      directives[:user].each(&gerrit.method(:create_user))
      directives[:project].each(&gerrit.method(:create_project))

      repos = directives[:project].reduce({}) do |acc, name:, **|
        acc[name.to_s] = git.clone(name: name)
        acc
      end

      directives[:change].reduce([]) do |acc, change|
        repo = repos.fetch(change[:project].to_s)

        gerrit.create_change(change, git: repo, changes: acc, users: directives[:user])

        acc.push(change)
      end
    end
  end
end
