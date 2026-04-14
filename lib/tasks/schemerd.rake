# frozen_string_literal: true

namespace :schemerd do
  desc "Generate Mermaid ER diagram from ActiveRecord models"
  task generate: :environment do
    Schemerd.generate
  end
end

# Auto-run after migrations in development
if defined?(Rails) && Rails.env.development?
  %w[db:migrate db:migrate:up db:migrate:down db:migrate:redo].each do |task_name|
    next unless Rake::Task.task_defined?(task_name)

    Rake::Task[task_name].enhance do
      if Schemerd.configuration.auto_generate
        Rake::Task["schemerd:generate"].invoke
      end
    end
  end
end
