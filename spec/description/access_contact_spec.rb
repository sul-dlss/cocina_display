# frozen_string_literal: true

require "spec_helper"

RSpec.describe CocinaDisplay::Description::AccessContact do
  subject { described_class.new(contact) }

  let(:contact) { {"value" => "test@example.com", "type" => "email"} }

  describe "#to_s" do
    it "returns the access value" do
      expect(subject.to_s).to eq("test@example.com")
    end
  end

  describe "#type" do
    it "returns the access type" do
      expect(subject.type).to eq("email")
    end
  end

  describe "#contact_email?" do
    it "returns true for email type" do
      expect(subject.contact_email?).to be true
    end

    context "when the type is not email" do
      let(:contact) { {"value" => "Test User"} }

      it "returns false" do
        expect(subject.contact_email?).to be false
      end
    end
  end
end
