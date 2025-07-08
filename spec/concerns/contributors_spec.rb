require "spec_helper"
require_relative "../../lib/cocina_display/cocina_record"

RSpec.describe CocinaDisplay::CocinaRecord do
  let(:contributors) { [] }
  let(:cocina_json) do
    {
      "description" => {
        "contributor" => contributors
      }
    }.to_json
  end
  let(:record) { described_class.new(cocina_json) }
  let(:with_date) { false }

  describe "#main_author" do
    subject { record.main_author(with_date: with_date) }

    context "with a primary author" do
      let(:contributors) do
        [
          {
            "name" => [{"value" => "Doe, John"}],
            "role" => [{"value" => "author"}],
            "status" => "primary"
          }
        ]
      end

      it { is_expected.to eq("Doe, John") }
    end

    context "with a primary contributor who is not an author" do
      let(:contributors) do
        [
          {
            "name" => [{"value" => "Smith, Jane"}],
            "role" => [{"value" => "editor"}],
            "status" => "primary"
          }
        ]
      end

      it { is_expected.to be_nil }
    end

    context "with contributors with no role" do
      let(:contributors) do
        [
          {
            "name" => [{"value" => "Doe, John"}]
          },
          {
            "name" => [{"value" => "Smith, Jane"}]
          }
        ]
      end

      it "uses the first contributor as the main author" do
        is_expected.to eq("Doe, John")
      end
    end

    context "with multiple authors, none primary" do
      let(:contributors) do
        [
          {
            "name" => [{"value" => "Doe, John"}],
            "role" => [{"value" => "author"}]
          },
          {
            "name" => [{"value" => "Smith, Jane"}],
            "role" => [{"value" => "creator"}]
          }
        ]
      end

      it "uses the first author" do
        is_expected.to eq("Doe, John")
      end
    end

    context "with life dates" do
      let(:with_date) { true }
      let(:contributors) do
        [
          {
            "name" => [
              {"structuredValue" => [
                {"value" => "Doe, John"},
                {"value" => "1970-2020", "type" => "life dates"}
              ]}
            ],
            "role" => [{"value" => "author"}]
          }
        ]
      end

      it { is_expected.to eq("Doe, John, 1970-2020") }
    end
  end

  describe "#additional_authors" do
    subject { record.additional_authors(with_date: with_date) }

    context "with a primary author and other authors" do
      let(:contributors) do
        [
          {
            "name" => [{"value" => "Doe, John"}],
            "role" => [{"value" => "author"}],
            "status" => "primary"
          },
          {
            "name" => [{"value" => "Smith, Jane"}],
            "role" => [{"value" => "author"}]
          }
        ]
      end

      it "returns additional authors excluding the primary one" do
        is_expected.to eq(["Smith, Jane"])
      end
    end
  end

  describe "#person_authors" do
    subject { record.person_authors(with_date: with_date) }

    context "with person authors" do
      let(:contributors) do
        [
          {
            "name" => [{"value" => "Doe, John"}],
            "role" => [{"value" => "author"}],
            "type" => "person",
            "status" => "primary"
          },
          {
            "name" => [{"value" => "Smith, Jane"}],
            "role" => [{"value" => "author"}],
            "type" => "person"
          }
        ]
      end

      it { is_expected.to eq(["Doe, John", "Smith, Jane"]) }
    end

    context "with no person authors" do
      let(:contributors) do
        [
          {
            "name" => [{"value" => "ACME Corp"}],
            "role" => [{"value" => "author"}],
            "type" => "organization"
          }
        ]
      end

      it { is_expected.to be_empty }
    end
  end

  describe "#impersonal_authors" do
    subject { record.impersonal_authors }

    context "with impersonal authors" do
      let(:contributors) do
        [
          {
            "name" => [{"value" => "ACME Corp"}],
            "role" => [{"value" => "author"}],
            "type" => "organization"
          },
          {
            "name" => [{"value" => "Smith, Jane"}],
            "role" => [{"value" => "author"}],
            "type" => "person"
          }
        ]
      end

      it { is_expected.to eq(["ACME Corp"]) }
    end

    context "with no impersonal authors" do
      let(:contributors) do
        [
          {
            "name" => [{"value" => "Doe, John"}],
            "role" => [{"value" => "author"}],
            "type" => "person"
          }
        ]
      end

      it { is_expected.to be_empty }
    end
  end

  describe "#organization_authors" do
    subject { record.organization_authors }

    context "with organization authors" do
      let(:contributors) do
        [
          {
            "name" => [{"value" => "ACME Corp"}],
            "role" => [{"value" => "author"}],
            "type" => "organization"
          },
          {
            "name" => [{"value" => "Smith, Jane"}],
            "role" => [{"value" => "author"}],
            "type" => "person"
          }
        ]
      end

      it { is_expected.to eq(["ACME Corp"]) }
    end

    context "with no organization authors" do
      let(:contributors) do
        [
          {
            "name" => [{"value" => "Doe, John"}],
            "role" => [{"value" => "author"}],
            "type" => "person"
          }
        ]
      end

      it { is_expected.to be_empty }
    end
  end

  describe "#conference_authors" do
    subject { record.conference_authors }

    context "with conference authors" do
      let(:contributors) do
        [
          {
            "name" => [{"value" => "ACME Conference"}],
            "role" => [{"value" => "author"}],
            "type" => "conference"
          },
          {
            "name" => [{"value" => "Smith, Jane"}],
            "role" => [{"value" => "author"}],
            "type" => "person"
          }
        ]
      end

      it { is_expected.to eq(["ACME Conference"]) }
    end

    context "with no conference authors" do
      let(:contributors) do
        [
          {
            "name" => [{"value" => "Doe, John"}],
            "role" => [{"value" => "author"}],
            "type" => "person"
          }
        ]
      end

      it { is_expected.to be_empty }
    end
  end

  describe "#sort_author" do
    subject { record.sort_author }

    context "with a main author" do
      let(:contributors) do
        [
          {
            "name" => [{"value" => "Doe, John  "}],
            "role" => [{"value" => "author"}],
            "status" => "primary"
          }
        ]
      end

      it "removes punctuation and whitespace" do
        is_expected.to eq("Doe John")
      end
    end

    context "with no main author" do
      let(:contributors) { [] }

      it { is_expected.to eq("\u{10FFFF}") } # Unicode replacement character for missing value
    end
  end
end
