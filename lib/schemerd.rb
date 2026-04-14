# frozen_string_literal: true

require "schemerd/version"
require "schemerd/configuration"
require "schemerd/generator"
require "schemerd/railtie" if defined?(Rails::Railtie)

module Schemerd
  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    def generate
      Generator.new(configuration).call
    end

    def reset_configuration!
      @configuration = Configuration.new
    end
  end
end
