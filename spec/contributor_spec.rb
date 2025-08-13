require "spec_helper"

require_relative "../lib/cocina_display/contributors/contributor"

RSpec.describe CocinaDisplay::Contributors::Contributor do
  subject { described_class.new(cocina) }

  describe "#author?" do
    context "with the author role" do
      let(:cocina) do
        {
          "role" => [{"value" => "author"}]
        }
      end

      it "returns true" do
        expect(subject.author?).to be true
      end
    end

    context "with multiple roles including author" do
      let(:cocina) do
        {
          "role" => [{"value" => "author"}, {"value" => "editor"}]
        }
      end

      it "returns true" do
        expect(subject.author?).to be true
      end
    end

    context "with the creator role" do
      let(:cocina) do
        {
          "role" => [{"value" => "Creator"}] # case insensitive match
        }
      end

      it "returns false" do
        expect(subject.author?).to be true
      end
    end

    context "with the primary investigator role" do
      let(:cocina) do
        {
          "role" => [{"value" => "primary investigator"}]
        }
      end

      it "returns true" do
        expect(subject.author?).to be true
      end
    end

    context "without the author or creator role" do
      let(:cocina) do
        {
          "role" => [{"value" => "editor"}]
        }
      end

      it "returns false" do
        expect(subject.author?).to be false
      end
    end
  end

  describe "#funder?" do
    context "with the funder role" do
      let(:cocina) do
        {
          "role" => [{"value" => "funder"}]
        }
      end

      it "returns true" do
        expect(subject.funder?).to be true
      end
    end

    context "with multiple roles including funder" do
      let(:cocina) do
        {
          "role" => [{"value" => "funder"}, {"value" => "editor"}]
        }
      end

      it "returns true" do
        expect(subject.funder?).to be true
      end
    end

    context "with the author role" do
      let(:cocina) do
        {
          "role" => [{"value" => "author"}]
        }
      end

      it "returns false" do
        expect(subject.funder?).to be false
      end
    end

    context "without the funder role" do
      let(:cocina) do
        {
          "role" => [{"value" => "editor"}]
        }
      end

      it "returns false" do
        expect(subject.funder?).to be false
      end
    end
  end

  describe "#person?" do
    context "with a person" do
      let(:cocina) do
        {
          "type" => "person"
        }
      end

      it "returns true" do
        expect(subject.person?).to be true
      end
    end

    context "with an organization" do
      let(:cocina) do
        {
          "type" => "organization"
        }
      end

      it "returns false" do
        expect(subject.person?).to be false
      end
    end
  end

  describe "#organization?" do
    context "with an organization" do
      let(:cocina) do
        {
          "type" => "organization"
        }
      end

      it "returns true" do
        expect(subject.organization?).to be true
      end
    end

    context "with a person" do
      let(:cocina) do
        {
          "type" => "person"
        }
      end

      it "returns false" do
        expect(subject.organization?).to be false
      end
    end
  end

  describe "#role?" do
    context "with roles defined" do
      let(:cocina) do
        {
          "role" => [{"value" => "author"}]
        }
      end

      it "returns true" do
        expect(subject.role?).to be true
      end
    end

    context "without roles defined" do
      let(:cocina) { {} }

      it "returns false" do
        expect(subject.role?).to be false
      end
    end
  end

  describe "#conference?" do
    context "with a conference" do
      let(:cocina) do
        {
          "type" => "conference"
        }
      end

      it "returns true" do
        expect(subject.conference?).to be true
      end
    end

    context "with a person" do
      let(:cocina) do
        {
          "type" => "person"
        }
      end

      it "returns false" do
        expect(subject.conference?).to be false
      end
    end
  end

  describe "#primary?" do
    context "with primary status" do
      let(:cocina) do
        {
          "status" => "primary"
        }
      end

      it "returns true" do
        expect(subject.primary?).to be true
      end
    end

    context "with no status" do
      let(:cocina) { {} }

      it "returns false" do
        expect(subject.primary?).to be false
      end
    end
  end

  # used for debugging, but tested for completeness
  describe "#to_s" do
    subject { described_class.new(cocina).to_s }

    context "with a person with a name" do
      let(:cocina) do
        {
          "type" => "person",
          "name" => [{"value" => "John Doe"}],
          "role" => [{"value" => "author"}]
        }
      end

      it { is_expected.to eq("John Doe: author") }
    end

    context "with an organization with a name" do
      let(:cocina) do
        {
          "type" => "organization",
          "name" => [{"value" => "ACME Corp"}],
          "role" => [{"value" => "publisher"}]
        }
      end

      it { is_expected.to eq("ACME Corp: publisher") }
    end

    context "person with multiple roles" do
      let(:cocina) do
        {
          "type" => "person",
          "name" => [{"value" => "John Doe"}],
          "role" => [
            {"value" => "author"},
            {"value" => "editor"}
          ]
        }
      end

      it { is_expected.to eq("John Doe: author and editor") }
    end
  end

  describe "#display_name" do
    subject { described_class.new(cocina).display_name(with_date: with_date) }
    let(:with_date) { false }

    context "with a person with no dates" do
      let(:cocina) do
        {
          "type" => "person",
          "name" => [{"value" => "John Doe"}]
        }
      end

      it { is_expected.to eq("John Doe") }
    end

    context "with a person with life dates" do
      let(:cocina) do
        {
          "type" => "person",
          "name" => [
            {"structuredValue" => [
              {"value" => "John Doe", "type" => "name"},
              {"value" => "1920 - 2000", "type" => "life dates"}
            ]}
          ]
        }
      end

      context "with date included" do
        let(:with_date) { true }

        it { is_expected.to eq("John Doe, 1920 - 2000") }
      end

      context "without date included" do
        let(:with_date) { false }

        it { is_expected.to eq("John Doe") }
      end
    end

    context "with a person with forename and surname" do
      let(:cocina) do
        {
          "type" => "person",
          "name" => [
            {"structuredValue" => [
              {"value" => "John", "type" => "forename"},
              {"value" => "Doe", "type" => "surname"}
            ]}
          ]
        }
      end

      it { is_expected.to eq("Doe, John") }
    end

    context "organization with multi-part name" do
      let(:cocina) do
        {
          "type" => "organization",
          "name" => [
            {"structuredValue" => [
              {"value" => "University of Michigan"},
              {"value" => "China Data Center"}
            ]}
          ]
        }
      end

      it { is_expected.to eq("University of Michigan, China Data Center") }
    end

    context "with a term of address" do
      let(:cocina) do
        {
          "type" => "person",
          "name" => [
            {"structuredValue" => [
              {"value" => "Dr.", "type" => "term of address"},
              {"value" => "Doe", "type" => "surname"},
              {"value" => "John", "type" => "forename"}
            ]}
          ]
        }
      end

      it { is_expected.to eq("Doe, John, Dr.") }
    end

    context "with term of address and name" do
      # from druid:kj040zn0537
      let(:cocina) do
        {
          "type" => "person",
          "name" => [
            {"structuredValue" => [
              {"value" => "duchess d'", "type" => "term of address"},
              {"value" => "Angoulême, Marie-Thérèse Charlotte de France", "type" => "name"},
              {"value" => "1778-1851", "type" => "life dates"}
            ]}
          ]
        }
      end
      let(:with_date) { true }

      it do
        is_expected.to eq("Angoulême, Marie-Thérèse Charlotte de France, duchess d', 1778-1851")
      end
    end

    context "with multiple forenames, surname, ordinal, dates" do
      let(:cocina) do
        {
          "type" => "person",
          "name" => [
            {"structuredValue" => [
              {"value" => "Rawnald", "type" => "forename"},
              {"value" => "Gregory", "type" => "forename"},
              {"value" => "Erickson", "type" => "surname"},
              {"value" => "II", "type" => "ordinal"},
              {"value" => "2008", "type" => "life dates"}
            ]}
          ]
        }
      end
      let(:with_date) { true }

      it { is_expected.to eq("Erickson, Rawnald Gregory II, 2008") }
    end

    context "with ordinal and term of address" do
      let(:cocina) do
        {
          "type" => "person",
          "name" => [
            {"structuredValue" => [
              {"value" => "Pope", "type" => "term of address"},
              {"value" => "John", "type" => "forename"},
              {"value" => "Paul", "type" => "forename"},
              {"value" => "II", "type" => "ordinal"}
            ]}
          ]
        }
      end

      it { is_expected.to eq("John Paul II, Pope") }
    end

    context "with parallelValue with display version" do
      # from druid:wz456vz8306
      let(:cocina) do
        {
          "type" => "person",
          "name" => [
            {
              "parallelValue" => [
                {"value" => "Love, Brian J. (Law teacher)"},
                {"value" => "Love, Brian J. (Law teacher), Stanford Law School graduate, J.D. (2007)", "type" => "display"}
              ]
            }
          ]
        }
      end

      it "uses the display version" do
        is_expected.to eq("Love, Brian J. (Law teacher), Stanford Law School graduate, J.D. (2007)")
      end
    end
  end

  describe "#forename" do
    subject { described_class.new(cocina).forename }

    context "with no explicitly marked forenames" do
      let(:cocina) do
        {
          "type" => "person",
          "name" => [
            {"value" => "John Doe"}
          ]
        }
      end

      it { is_expected.to be_nil }
    end

    context "with explicitly marked forenames" do
      let(:cocina) do
        {
          "type" => "person",
          "name" => [
            {"structuredValue" => [
              {"value" => "Rawnald", "type" => "forename"},
              {"value" => "Gregory", "type" => "forename"},
              {"value" => "Erickson", "type" => "surname"},
              {"value" => "II", "type" => "ordinal"},
              {"value" => "2008", "type" => "life dates"}
            ]}
          ]
        }
      end

      it { is_expected.to eq("Rawnald Gregory II") }
    end
  end

  describe "#surname" do
    subject { described_class.new(cocina).surname }

    context "with no explicitly marked surnames" do
      let(:cocina) do
        {
          "type" => "person",
          "name" => [
            {"value" => "John Doe"}
          ]
        }
      end

      it { is_expected.to be_nil }
    end

    context "with explicitly marked surnames" do
      let(:cocina) do
        {
          "type" => "person",
          "name" => [
            {"structuredValue" => [
              {"value" => "Rawnald", "type" => "forename"},
              {"value" => "Gregory", "type" => "forename"},
              {"value" => "Erickson", "type" => "surname"},
              {"value" => "II", "type" => "ordinal"},
              {"value" => "2008", "type" => "life dates"}
            ]}
          ]
        }
      end

      it { is_expected.to eq("Erickson") }
    end
  end
end
