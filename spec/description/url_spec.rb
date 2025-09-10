# frozen_string_literal: true

require "spec_helper"

RSpec.describe CocinaDisplay::Description::Url do
  subject { described_class.new(url) }

  let(:url) { {"value" => "https://example.com", "displayLabel" => "My favorite website"} }

  describe "#label" do
    it "returns the display label" do
      expect(subject.label).to eq("Location")
    end
  end

  describe "#link_text" do
    it "returns the display label" do
      expect(subject.link_text).to eq("My favorite website")
    end

    context "when there is no displayLabel" do
      let(:url) { {"value" => "https://example.com"} }

      it "returns the value as link text" do
        expect(subject.link_text).to be_nil
      end
    end
  end
end
