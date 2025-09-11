require "spec_helper"

RSpec.describe CocinaDisplay::Contributors::Contributor do
  let(:instance) { described_class.new(cocina) }

  describe "#author?" do
    subject { instance.author? }

    context "with the author role" do
      let(:cocina) do
        {
          "role" => [{"value" => "author"}]
        }
      end

      it { is_expected.to be true }
    end

    context "with multiple roles including author" do
      let(:cocina) do
        {
          "role" => [{"value" => "author"}, {"value" => "editor"}]
        }
      end

      it { is_expected.to be true }
    end

    context "with the creator role" do
      let(:cocina) do
        {
          "role" => [{"value" => "Creator"}] # case insensitive match
        }
      end

      it { is_expected.to be true }
    end

    context "with the primary investigator role" do
      let(:cocina) do
        {
          "role" => [{"value" => "primary investigator"}]
        }
      end

      it { is_expected.to be true }
    end

    context "without the author or creator role" do
      let(:cocina) do
        {
          "role" => [{"value" => "editor"}]
        }
      end

      it { is_expected.to be false }
    end
  end

  describe "#funder?" do
    subject { instance.funder? }

    context "with the funder role" do
      let(:cocina) do
        {
          "role" => [{"value" => "funder"}]
        }
      end

      it { is_expected.to be true }
    end

    context "with multiple roles including funder" do
      let(:cocina) do
        {
          "role" => [{"value" => "funder"}, {"value" => "editor"}]
        }
      end

      it { is_expected.to be true }
    end

    context "with the author role" do
      let(:cocina) do
        {
          "role" => [{"value" => "author"}]
        }
      end

      it { is_expected.to be false }
    end

    context "without the funder role" do
      let(:cocina) do
        {
          "role" => [{"value" => "editor"}]
        }
      end

      it { is_expected.to be false }
    end
  end

  describe "#person?" do
    subject { instance.person? }

    context "with a person" do
      let(:cocina) do
        {
          "type" => "person"
        }
      end

      it { is_expected.to be true }
    end

    context "with an organization" do
      let(:cocina) do
        {
          "type" => "organization"
        }
      end

      it { is_expected.to be false }
    end
  end

  describe "#organization?" do
    subject { instance.organization? }

    context "with an organization" do
      let(:cocina) do
        {
          "type" => "organization"
        }
      end

      it { is_expected.to be true }
    end

    context "with a person" do
      let(:cocina) do
        {
          "type" => "person"
        }
      end

      it { is_expected.to be false }
    end
  end

  describe "#role?" do
    subject { instance.role? }

    context "with roles defined" do
      let(:cocina) do
        {
          "role" => [{"value" => "author"}]
        }
      end

      it { is_expected.to be true }
    end

    context "without roles defined" do
      let(:cocina) { {} }

      it { is_expected.to be false }
    end
  end

  describe "#conference?" do
    subject { instance.conference? }

    context "with a conference" do
      let(:cocina) do
        {
          "type" => "conference"
        }
      end

      it { is_expected.to be true }
    end

    context "with a person" do
      let(:cocina) do
        {
          "type" => "person"
        }
      end

      it { is_expected.to be false }
    end
  end

  describe "#primary?" do
    subject { instance.primary? }

    context "with primary status" do
      let(:cocina) do
        {
          "status" => "primary"
        }
      end

      it { is_expected.to be true }
    end

    context "with no status" do
      let(:cocina) { {} }

      it { is_expected.to be false }
    end
  end

  describe "#to_s" do
    subject { instance.to_s }

    context "with a person with a name" do
      let(:cocina) do
        {
          "type" => "person",
          "name" => [
            {"structuredValue" => [
              {"value" => "John Doe", "type" => "name"},
              {"value" => "1920 - 2000", "type" => "life dates"}
            ]}
          ],
          "role" => [{"value" => "author"}]
        }
      end

      it { is_expected.to eq("John Doe, 1920 - 2000") }
    end

    context "with an organization with a name" do
      let(:cocina) do
        {
          "type" => "organization",
          "name" => [{"value" => "ACME Corp"}],
          "role" => [{"value" => "publisher"}]
        }
      end

      it { is_expected.to eq("ACME Corp") }
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

      it { is_expected.to eq("John Doe") }
    end
  end

  describe "#display_name" do
    subject { instance.display_name(with_date: with_date) }
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

    context "with no name values" do
      let(:cocina) do
        {
          "type" => "person",
          "name" => [{}]
        }
      end

      it { is_expected.to be_nil }
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
    subject { instance.forename }

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
    subject { instance.surname }

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

  describe "#identifiers" do
    subject { instance.identifiers }

    context "with no ORCID identifier" do
      let(:cocina) do
        {
          "type" => "person",
          "name" => [
            {"value" => "John Doe"}
          ]
        }
      end

      it { is_expected.to be_empty }
    end

    context "with an ORCID identifier" do
      let(:cocina) do
        {
          "type" => "person",
          "name" => [
            {"value" => "John Doe"}
          ],
          "identifier" => [
            {"type" => "ORCID", "id" => "0000-0002-1825-0097"}
          ]
        }
      end

      it { is_expected.to eq([CocinaDisplay::Identifier.new({"type" => "ORCID", "id" => "0000-0002-1825-0097"})]) }
    end
  end
end
