# frozen_string_literal: true

module Schemerd
  class Configuration
    attr_accessor :output_directory,
                  :output_filename,
                  :header,
                  :excluded_prefixes,
                  :auto_generate,
                  :base_class

    def initialize
      @output_directory  = "doc"
      @output_filename   = "erd.md"
      @header            = "# Entity Relationship Diagram\n\n" \
                           "Auto-generated from ActiveRecord models. Do not edit manually."
      @excluded_prefixes = []
      @auto_generate     = true
      @base_class        = "ApplicationRecord"
    end

    def output_path
      Rails.root.join(output_directory, output_filename)
    end
  end
end
