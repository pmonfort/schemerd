# frozen_string_literal: true

module Schemerd
  module Generators
    class InstallGenerator < Rails::Generators::Base
      desc "Create a Schemerd initializer with default configuration"
      source_root File.expand_path("templates", __dir__)

      def copy_initializer
        template "initializer.rb", "config/initializers/schemerd.rb"
      end
    end
  end
end
