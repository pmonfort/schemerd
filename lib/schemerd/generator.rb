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
      ActiveRecord::Base.connection.schema_cache.clear!
      Rails.application.eager_load!

      base = @config.base_class.constantize
      all_models = base.descendants
        .reject(&:abstract_class?)
        .reject { |m| excluded?(m.name) }
        .select { |m| m.table_exists? rescue false }

      all_models.each(&:reset_column_information)

      @sti_children = Hash.new { |h, k| h[k] = [] }
      sti, non_sti = all_models.partition { |m| sti_child?(m) }
      sti.each { |m| @sti_children[m.superclass.name] << m.name }

      non_sti.sort_by(&:name)
    end

    def excluded?(model_name)
      @config.excluded_prefixes.any? { |prefix| model_name.start_with?(prefix) }
    end

    def sti_child?(model)
      model.superclass != @config.base_class.constantize &&
        !model.superclass.abstract_class? &&
        model.table_name == model.superclass.table_name
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
        model.reflect_on_all_associations.reject { |a| a.options[:through] }.each do |assoc|
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
        subtypes = @sti_children.fetch(model.name, [])
        sort_columns(model.columns).each do |col|
          pk = col.name == model.primary_key ? "PK" : ""
          comment = col.name == "type" && subtypes.any? ? "\"#{subtypes.sort.join(', ')}\"" : ""
          type = col.type || "string"
          lines << "        #{type} #{col.name} #{pk} #{comment}".rstrip
        end
        lines << "    }"
        lines << ""
      end

      lines
    end

    TIMESTAMP_COLUMNS = %w[created_at updated_at].freeze

    def sort_columns(columns)
      pk, timestamps, rest = [], [], []
      columns.each do |col|
        if col.name == "id"
          pk << col
        elsif TIMESTAMP_COLUMNS.include?(col.name)
          timestamps << col
        else
          rest << col
        end
      end
      pk + rest.sort_by(&:name) + timestamps.sort_by(&:name)
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
      when :has_and_belongs_to_many
        "#{source} }o--o{ #{target} : \"#{assoc.name}\""
      end
    end
  end
end
