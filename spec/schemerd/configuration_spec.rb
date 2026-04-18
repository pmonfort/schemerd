# frozen_string_literal: true

require "spec_helper"

RSpec.describe Schemerd::Configuration do
  subject(:config) { described_class.new }

  it "has default output_directory" do
    expect(config.output_directory).to eq("docs")
  end

  it "has default output_filename" do
    expect(config.output_filename).to eq("erd.md")
  end

  it "has default header" do
    expect(config.header).to include("Entity Relationship Diagram")
  end

  it "has default excluded_prefixes" do
    expect(config.excluded_prefixes).to eq([])
  end

  it "has default auto_generate" do
    expect(config.auto_generate).to be true
  end

  it "has default base_class" do
    expect(config.base_class).to eq("ApplicationRecord")
  end

  it "allows setting output_directory" do
    config.output_directory = "doc/diagrams"
    expect(config.output_directory).to eq("doc/diagrams")
  end
end
