# frozen_string_literal: true

require "set"
require "fileutils"

module Schemerd
  class Generator
    def initialize(config)
      @config = config
    end

    def call
      models = load_models
      content = build_diagram(models)

      output_path = @config.output_path
      FileUtils.mkdir_p(File.dirname(output_path))
      File.write(output_path, content)

      puts "Schemerd: ERD written to #{output_path}"
      content
    end

    private

    def load_models
      Rails.application.eager_load!

      base = @config.base_class.constantize
      base.descendants
        .reject(&:abstract_class?)
        .reject { |m| excluded?(m.name) }
        .select { |m| m.table_exists? rescue false }
        .sort_by(&:name)
    end

    def excluded?(model_name)
      @config.excluded_prefixes.any? { |prefix| model_name.start_with?(prefix) }
    end

    def build_diagram(models)
      lines = []

      lines << @config.header
      lines << ""
      lines << "```mermaid"
      lines << "erDiagram"

      lines.concat(associations_section(models))
      lines << ""
      lines.concat(entities_section(models))

      lines << "```"
      lines.join("\n") + "\n"
    end

    def associations_section(models)
      lines = []
      seen = Set.new
      model_names = models.map(&:name).to_set

      models.each do |model|
        model.reflect_on_all_associations.each do |assoc|
          target_name = assoc.klass.name rescue next
          next unless model_names.include?(target_name)

          pair = [model.name, target_name].sort
          next if seen.include?(pair)
          seen.add(pair)

          line = relationship_line(model.name, target_name, assoc)
          lines << "    #{line}" if line
        end
      end

      lines
    end

    def entities_section(models)
      lines = []

      models.each do |model|
        lines << "    #{model.name} {"
        model.columns.each do |col|
          pk = col.name == "id" ? "PK" : ""
          type = col.type || "string"
          lines << "        #{type} #{col.name} #{pk}".rstrip
        end
        lines << "    }"
        lines << ""
      end

      lines
    end

    def relationship_line(source, target, assoc)
      case assoc.macro
      when :belongs_to
        if assoc.options[:optional]
          "#{source} }o--o| #{target} : \"#{assoc.name}\""
        else
          "#{source} }o--|| #{target} : \"#{assoc.name}\""
        end
      when :has_many
        "#{source} ||--o{ #{target} : \"#{assoc.name}\""
      when :has_one
        "#{source} ||--o| #{target} : \"#{assoc.name}\""
      end
    end
  end
end
