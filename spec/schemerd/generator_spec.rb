# frozen_string_literal: true

require "spec_helper"

RSpec.describe Schemerd::Generator do
  let(:config) { Schemerd::Configuration.new }
  let(:generator) { described_class.new(config) }

  def build_column(name, type = :string)
    double("Column", name: name, type: type)
  end

  describe "#sort_columns" do
    it "puts PK first, timestamps last, rest alphabetical" do
      columns = [
        build_column("updated_at", :datetime),
        build_column("name"),
        build_column("id", :integer),
        build_column("email"),
        build_column("created_at", :datetime),
        build_column("age", :integer),
      ]

      sorted = generator.send(:sort_columns, columns)
      names = sorted.map(&:name)

      expect(names).to eq(%w[id age email name created_at updated_at])
    end

    it "handles tables without id column" do
      columns = [
        build_column("tag_id", :integer),
        build_column("post_id", :integer),
        build_column("created_at", :datetime),
      ]

      sorted = generator.send(:sort_columns, columns)
      names = sorted.map(&:name)

      expect(names).to eq(%w[post_id tag_id created_at])
    end

    it "handles tables without timestamps" do
      columns = [
        build_column("value"),
        build_column("id", :integer),
        build_column("key"),
      ]

      sorted = generator.send(:sort_columns, columns)
      names = sorted.map(&:name)

      expect(names).to eq(%w[id key value])
    end
  end

  describe "#excluded?" do
    it "excludes models matching a prefix" do
      config.excluded_prefixes = ["Flipper::"]
      expect(generator.send(:excluded?, "Flipper::Feature")).to be true
    end

    it "does not exclude models not matching any prefix" do
      config.excluded_prefixes = ["Flipper::"]
      expect(generator.send(:excluded?, "User")).to be false
    end

    it "handles multiple prefixes" do
      config.excluded_prefixes = ["Flipper::", "Ahoy::"]
      expect(generator.send(:excluded?, "Ahoy::Event")).to be true
      expect(generator.send(:excluded?, "User")).to be false
    end
  end

  describe "#relationship_line" do
    it "generates belongs_to line" do
      assoc = double("Assoc", macro: :belongs_to, name: "author", options: {})
      line = generator.send(:relationship_line, "Post", "User", assoc)
      expect(line).to eq('Post }o--|| User : "author"')
    end

    it "generates optional belongs_to line" do
      assoc = double("Assoc", macro: :belongs_to, name: "category", options: { optional: true })
      line = generator.send(:relationship_line, "Post", "Category", assoc)
      expect(line).to eq('Post }o--o| Category : "category"')
    end

    it "generates has_many line" do
      assoc = double("Assoc", macro: :has_many, name: "posts", options: {})
      line = generator.send(:relationship_line, "User", "Post", assoc)
      expect(line).to eq('User ||--o{ Post : "posts"')
    end

    it "generates has_one line" do
      assoc = double("Assoc", macro: :has_one, name: "profile", options: {})
      line = generator.send(:relationship_line, "User", "Profile", assoc)
      expect(line).to eq('User ||--o| Profile : "profile"')
    end

    # e.g. Doctor -> Appointment -> Patient already covers the path; skip the direct Doctor -> Patient
    it "skips has_many :through associations" do
      through_assoc = double("Assoc", macro: :has_many, name: "patients", options: { through: :appointments })
      appointment_klass = double("Klass", name: "Appointment")
      direct_assoc = double("Assoc", macro: :has_many, name: "appointments", options: {}, klass: appointment_klass)

      doctor = double("Model",
        name: "Doctor",
        reflect_on_all_associations: [through_assoc, direct_assoc],
      )
      appointment = double("Model",
        name: "Appointment",
        reflect_on_all_associations: [],
      )

      model_names = [doctor, appointment].map(&:name).to_set
      lines = generator.send(:associations_section, [doctor, appointment])

      expect(lines.any? { |l| l.include?("Patient") }).to be false
      expect(lines.any? { |l| l.include?("Appointment") }).to be true
    end

    it "generates has_and_belongs_to_many line" do
      assoc = double("Assoc", macro: :has_and_belongs_to_many, name: "tags", options: {})
      line = generator.send(:relationship_line, "Post", "Tag", assoc)
      expect(line).to eq('Post }o--o{ Tag : "tags"')
    end
  end

  describe "STI handling" do
    it "annotates type column with subtypes" do
      generator.instance_variable_set(:@sti_children, {
        "Vehicle" => ["Car", "Truck"],
      })

      model = double("Model",
        name: "Vehicle",
        primary_key: "id",
        columns: [
          build_column("id", :integer),
          build_column("type"),
          build_column("name"),
        ],
      )

      lines = generator.send(:entities_section, [model])
      type_line = lines.find { |l| l.include?("type") }

      expect(type_line).to include('"Car, Truck"')
    end

    it "does not annotate type column without subtypes" do
      generator.instance_variable_set(:@sti_children, {})

      model = double("Model",
        name: "User",
        primary_key: "id",
        columns: [
          build_column("id", :integer),
          build_column("type"),
        ],
      )

      lines = generator.send(:entities_section, [model])
      type_line = lines.find { |l| l.include?("type") }

      expect(type_line).not_to include('"')
    end
  end
end
