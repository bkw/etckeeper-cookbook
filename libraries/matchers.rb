if defined?(ChefSpec)
  if ChefSpec::VERSION
    if Gem::Version.new(ChefSpec::VERSION) > Gem::Version.new('4.1.0')
      ChefSpec.define_matcher(:etckeeper_git_remote)
    else
      ChefSpec::Runner.define_runner_method(:etckeeper_git_remote)
    end

    def create_etckeeper_git_remote(resource)
      ChefSpec::Matchers::ResourceMatcher.new(
        :etckeeper_git_remote,
        :create,
        resource
      )
    end

    def delete_etckeeper_git_remote(resource)
      ChefSpec::Matchers::ResourceMatcher.new(
        :etckeeper_git_remote,
        :delete,
        resource
      )
    end
  end
end
