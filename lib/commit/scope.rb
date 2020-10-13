# frozen_string_literal: true

require "pathname"
require "yaml"

require_relative "config"

module Commit
  # Scopes represent a configured context to run tools in.
  #
  class Scope
    class << self
      def each(root = Dir.pwd, &block)
        return enum_for(:each, root) unless block_given?

        root = Pathname.new(root)
        root.glob("**/*", File::FNM_DOTMATCH).select { |path|
          path.basename.fnmatch?(COMMIT_TOOLS_DIRECTORY)
        }.reject { |path|
          # Ignore commit directories within hidden folders.
          #
          path.dirname.to_s.split("/").any? { |part| part[0] == "." }
        }.reject { |path|
          # Ignore commit directories within tmp folders.
          #
          path.dirname.to_s.split("/").any? { |part| part == "tmp" }
        }.map { |path|
          new(path: path)
        }.each(&block)
      end
    end

    attr_reader :path, :config

    def initialize(path:)
      @path = Pathname.new(path)
      @config = Config.new(load_config(@path.join(CONFIG_FILE)))
    end

    # @api private
    private def load_config(config_path)
      if config_path.exist?
        YAML.safe_load(config_path.read)
      else
        {}
      end
    end

    # @api private
    COMMIT_TOOLS_DIRECTORY = ".commit"
    # @api private
    CONFIG_FILE = "config.yml"
  end
end
