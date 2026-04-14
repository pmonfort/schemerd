# frozen_string_literal: true

module Schemerd
  class Railtie < Rails::Railtie
    rake_tasks do
      load File.expand_path("../../tasks/schemerd.rake", __dir__)
    end
  end
end
