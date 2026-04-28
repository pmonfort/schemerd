# frozen_string_literal: true

namespace :schemerd do
  desc "Generate Mermaid ER diagram from ActiveRecord models"
  task generate: :environment do
    Schemerd.generate
  end
end

if defined?(Rails) && Rails.env.development?
  migration_tasks = %w[db:migrate db:migrate:up db:migrate:down db:migrate:redo db:rollback]

  migration_tasks.each do |task|
    next unless Rake::Task.task_defined?(task)

    Rake::Task[task].enhance do
      Rake::Task[Rake.application.top_level_tasks.last].enhance do
        Schemerd.generate if Schemerd.configuration.auto_generate
      end
    end
  end
end
