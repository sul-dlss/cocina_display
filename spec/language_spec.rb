# frozen_string_literal: true

require "spec_helper"

RSpec.describe CocinaDisplay::Language do
  subject { described_class.new(language) }

  describe "#label" do
    let(:language) do
      {"value" => "English"}
    end

    it "returns the label for language" do
      expect(subject.label).to eq "Language"
    end
  end
end
