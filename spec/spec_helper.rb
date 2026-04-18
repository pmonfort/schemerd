# frozen_string_literal: true

require "schemerd"

RSpec.configure do |config|
  config.after { Schemerd.reset_configuration! }
end
