# frozen_string_literal: true

require "spec_helper"

RSpec.describe CocinaDisplay::Access do
  subject { described_class.new(access) }

  let(:access) { {"value" => "Test Access", "type" => "repository"} }

  describe "#to_s" do
    it "returns the access value" do
      expect(subject.to_s).to eq("Test Access")
    end
  end

  describe "#type" do
    it "returns the access type" do
      expect(subject.type).to eq("repository")
    end
  end

  describe "#label" do
    it "returns the access label" do
      expect(subject.label).to eq("Repository")
    end

    context "when a displayLabel is set" do
      let(:access) { {"value" => "Test Access", "displayLabel" => "Custom Repository"} }

      it "returns the display label" do
        expect(subject.label).to eq("Custom Repository")
      end
    end

    context "when there is no type set" do
      let(:access) { {"value" => "Test Access"} }

      it "returns the default label" do
        expect(subject.label).to eq("Location")
      end
    end
  end

  describe "#contact_email?" do
    it "always returns false" do
      expect(subject.contact_email?).to be false
    end
  end
end
