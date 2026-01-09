require "spec_helper"

RSpec.describe CocinaDisplay::CocinaRecord do
  let(:contributors) { [] }
  let(:cocina_json) do
    {
      "description" => {
        "contributor" => contributors
      }
    }.to_json
  end
  let(:record) { described_class.from_json(cocina_json) }
  let(:with_date) { false }

  describe "#main_contributor_name" do
    subject { record.main_contributor_name(with_date: with_date) }

    context "with a primary contributor" do
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

      it { is_expected.to eq("Smith, Jane") }
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

    context "with multiple contributors, none primary" do
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

      it "uses the first contributor" do
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

    context "with contributors with parallel names" do
      # adapted from druid:bb070yy8209
      let(:contributors) do
        [
          {
            "name" => [
              {
                "parallelValue" => [
                  {
                    "value" => "Ṣabāḥ, 1927-2014",
                    "type" => "transliteration"
                  },
                  {
                    "value" => "صباح، 1927-2014",
                    "status" => "primary"
                  }
                ]
              }
            ],
            "type" => "person",
            "status" => "primary",
            "role" => [{"value" => "actor"}]
          },
          {
            "name" => [
              {
                "parallelValue" => [
                  {"value" => "ذو الفقار، محمود"},
                  {"value" => "Dhū al-Fiqār, Maḥmūd"}
                ]
              }
            ],
            "type" => "person",
            "role" => [{"value" => "director"}]
          }
        ]
      end

      it "returns the primary parallel name for the primary contributor" do
        is_expected.to eq("صباح، 1927-2014")
      end
    end
  end

  describe "#additional_contributor_names" do
    subject { record.additional_contributor_names(with_date: with_date) }

    context "with a primary contributor and other contributors" do
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

    context "with contributors with parallel names" do
      # adapted from druid:bb070yy8209
      let(:contributors) do
        [
          {
            "name" => [
              {
                "parallelValue" => [
                  {
                    "value" => "Ṣabāḥ, 1927-2014",
                    "type" => "transliteration"
                  },
                  {
                    "value" => "صباح، 1927-2014",
                    "status" => "primary"
                  }
                ]
              }
            ],
            "type" => "person",
            "status" => "primary",
            "role" => [{"value" => "actor"}]
          },
          {
            "name" => [
              {
                "parallelValue" => [
                  {"value" => "ذو الفقار، محمود"},
                  {"value" => "Dhū al-Fiqār, Maḥmūd"}
                ]
              }
            ],
            "type" => "person",
            "role" => [{"value" => "director"}]
          }
        ]
      end

      it "returns the parallel names for non-primary contributors" do
        is_expected.to eq(["ذو الفقار، محمود", "Dhū al-Fiqār, Maḥmūd"])
      end
    end

    context "with contributors and an event contributor from imprint statement" do
      # adapted from druid:kf879tn8532
      let(:contributors) do
        [
          {
            "name" => [
              {
                "structuredValue" => [
                  {"value" => "Rifat Paşa, Mehmet Sadık", "type" => "name"},
                  {"value" => "1807-1856", "type" => "life dates"}
                ]
              }
            ],
            "type" => "person",
            "status" => "primary",
            "role" => [{"value" => "author"}]
          },
          {
            "name" => [
              {
                "structuredValue" => [
                  {"value" => "Gabbay, Yehezkel", "type" => "name"},
                  {"value" => "1825-1898", "type" => "life dates"}
                ]
              }
            ],
            "type" => "person",
            "role" => [{"value" => "translator"}]
          },
          {
            "name" => [
              {
                "structuredValue" => [
                  {"value" => "Jerusalmi, Isaac", "type" => "name"},
                  {"value" => "1928-2018", "type" => "life dates"}
                ]
              }
            ],
            "type" => "person",
            "role" => [{"value" => "editor"}]
          },
          {
            "name" => [
              {
                "structuredValue" => [
                  {"value" => "Taube Center for Jewish Studies (Stanford University)"},
                  {"value" => "Sephardic Studies Project"}
                ]
              }
            ],
            "type" => "organization"
          }
        ]
      end
      let(:events) do
        [
          {
            "date" => [
              {"value" => "[1990?]", "type" => "publication"}
            ],
            "contributor" => [
              {
                "name" => [
                  {"value" => "[Isaac Jerushalmi]"}
                ],
                "type" => "organization",
                "role" => [
                  {
                    "value" => "publisher",
                    "code" => "pbl",
                    "uri" => "http://id.loc.gov/vocabulary/relators/pbl",
                    "source" => {"code" => "marcrelator", "uri" => "http://id.loc.gov/vocabulary/relators/"}
                  }
                ]
              }
            ],
            "location" => [
              {"value" => "[Cincinnati, Ohio?]"}
            ],
            "note" => [
              {"value" => "[Enl. and restored ed.].", "type" => "edition"}
            ]
          }
        ]
      end
      let(:cocina_json) do
        {
          "description" => {
            "contributor" => contributors,
            "event" => events
          }
        }.to_json
      end

      it "does not include the event contributor" do
        is_expected.to eq([
          "Gabbay, Yehezkel",
          "Jerusalmi, Isaac",
          "Taube Center for Jewish Studies (Stanford University), Sephardic Studies Project"
        ])
      end
    end
  end

  describe "#person_contributor_names" do
    subject { record.person_contributor_names(with_date: with_date) }

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

    context "with contributors with parallel names" do
      # adapted from druid:bb070yy8209
      let(:contributors) do
        [
          {
            "name" => [
              {
                "parallelValue" => [
                  {
                    "value" => "Ṣabāḥ, 1927-2014",
                    "type" => "transliteration"
                  },
                  {
                    "value" => "صباح، 1927-2014",
                    "status" => "primary"
                  }
                ]
              }
            ],
            "type" => "person",
            "status" => "primary",
            "role" => [{"value" => "actor"}]
          },
          {
            "name" => [
              {
                "parallelValue" => [
                  {"value" => "ذو الفقار، محمود"},
                  {"value" => "Dhū al-Fiqār, Maḥmūd"}
                ]
              }
            ],
            "type" => "person",
            "role" => [{"value" => "director"}]
          }
        ]
      end

      it "returns all parallel contributor names separately" do
        is_expected.to eq(["Ṣabāḥ, 1927-2014", "صباح، 1927-2014", "ذو الفقار، محمود", "Dhū al-Fiqār, Maḥmūd"])
      end
    end
  end

  describe "#impersonal_contributor_names" do
    subject { record.impersonal_contributor_names }

    context "with impersonal contributors" do
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

  describe "#organization_contributor_names" do
    subject { record.organization_contributor_names }

    context "with organization contributors" do
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

  describe "#conference_contributor_names" do
    subject { record.conference_contributor_names }

    context "with conference contributors" do
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

  describe "#sort_contributor_name" do
    subject { record.sort_contributor_name }

    context "with a main contributor" do
      let(:contributors) do
        [
          {
            "name" => [{"value" => "Doe, John"}],
            "role" => [{"value" => "author"}],
            "status" => "primary"
          }
        ]
      end

      it "removes punctuation and adds sort title" do
        is_expected.to eq("Doe John \u{10FFFF}")
      end
    end

    context "with no main author and no title" do
      let(:contributors) { [] }

      it { is_expected.to eq("\u{10FFFF} \u{10FFFF}") } # Unicode replacement character for missing value
    end

    context "with a main contributor and a title" do
      let(:cocina_json) do
        {
          "description" => {
            "contributor" => [
              {
                "name" => [{"value" => "Doe, John"}],
                "role" => [{"value" => "author"}],
                "status" => "primary"
              }
            ],
            "title" => [{"value" => "Sample Title"}]
          }
        }.to_json
      end

      it "appends the title for disambiguation" do
        is_expected.to eq("Doe John Sample Title")
      end
    end
  end

  describe "#contributor_names_by_role" do
    subject { record.contributor_names_by_role(with_date: with_date) }

    context "with multiple contributors and roles and with date" do
      let(:with_date) { true }
      let(:contributors) do
        [
          {
            "name" => [{"value" => "Doe, John"}],
            "role" => [{"value" => "author"}],
            "type" => "person"
          },
          {
            "name" => [{"value" => "Smith, Jane"}],
            "role" => [{"value" => "editor"}],
            "type" => "person"
          },
          {
            "name" => [{"value" => "ACME Corp"}],
            "role" => [{"value" => "publisher"}],
            "type" => "organization"
          },
          # from druid:kj040zn0537
          {
            "type" => "person",
            "name" => [
              {
                "structuredValue" => [
                  {"value" => "Lasinio, Carlo", "type" => "name"},
                  {"value" => "1759-1838", "type" => "life dates"}
                ]
              }
            ],
            "status" => "primary",
            "role" => [
              {"code" => "egr", "source" => {"code" => "marcrelator"}}
            ]
          }
        ]
      end

      it "groups contributors by their roles" do
        is_expected.to eq({
          "author" => ["Doe, John"],
          "editor" => ["Smith, Jane"],
          "publisher" => ["ACME Corp"],
          "engraver" => ["Lasinio, Carlo, 1759-1838"]
        })
      end
    end

    context "with no contributors" do
      let(:contributors) { [] }

      it { is_expected.to be_empty }
    end

    context "with contributors that have empty names" do
      let(:contributors) do
        [
          {
            "name" => [{}],
            "role" => [{"value" => "author"}],
            "type" => "person"
          },
          {
            "name" => [{"value" => "John Smith"}],
            "role" => [{"value" => "editor"}],
            "type" => "person"
          }
        ]
      end

      it "returns only names with values" do
        is_expected.to eq({
          "editor" => ["John Smith"]
        })
      end
    end
  end

  describe "#contributors_by_role" do
    subject(:result) { record.contributors_by_role(with_date: with_date) }

    context "with multiple contributors and roles and with date" do
      let(:with_date) { true }
      let(:contributors) do
        [
          {
            "name" => [{"value" => "Doe, John"}],
            "role" => [{"value" => "author"}],
            "type" => "person"
          },
          {
            "name" => [{"value" => "Smith, Jane"}],
            "role" => [{"value" => "editor"}],
            "type" => "person"
          },
          {
            "name" => [{"value" => "ACME Corp"}],
            "role" => [{"value" => "publisher"}],
            "type" => "organization"
          },
          # from druid:kj040zn0537
          {
            "type" => "person",
            "name" => [
              {
                "structuredValue" => [
                  {"value" => "Lasinio, Carlo", "type" => "name"},
                  {"value" => "1759-1838", "type" => "life dates"}
                ]
              }
            ],
            "status" => "primary",
            "role" => [
              {"code" => "egr", "source" => {"code" => "marcrelator"}}
            ]
          }
        ]
      end

      it "groups contributors by their roles" do
        expect(result["author"]).to eq [CocinaDisplay::Contributors::Contributor.new(contributors[0])]
        expect(result["editor"]).to eq [CocinaDisplay::Contributors::Contributor.new(contributors[1])]
        expect(result["publisher"]).to eq [CocinaDisplay::Contributors::Contributor.new(contributors[2])]
        expect(result["engraver"]).to eq [CocinaDisplay::Contributors::Contributor.new(contributors[3])]
      end
    end

    context "with no contributors" do
      let(:contributors) { [] }

      it { is_expected.to be_empty }
    end

    context "when contributor has no declared role" do
      let(:contributors) do
        [
          # from druid:bb737zp0787
          {
            "type" => "person",
            "name" => [
              {
                "structuredValue" => [
                  {"value" => "Paget, Francis Edward", "type" => "name"},
                  {"value" => "1759-1838", "type" => "life dates"}
                ]
              }
            ],
            "status" => "primary",
            "role" => []
          }
        ]
      end

      it 'gives a role of "associated with"' do
        expect(result[nil]).to eq [CocinaDisplay::Contributors::Contributor.new(contributors[0])]
      end
    end
  end

  describe "#contributor_display_data" do
    subject(:result) { record.contributor_display_data }

    context "with multiple contributors and roles and with date" do
      let(:with_date) { true }
      let(:contributors) do
        [
          {
            "name" => [{"value" => "Doe, John"}],
            "role" => [{"value" => "author"}],
            "type" => "person"
          },
          {
            "name" => [{"value" => "Smith, Jane"}],
            "role" => [{"value" => "editor"}],
            "type" => "person"
          },
          {
            "name" => [{"value" => "ACME Corp"}],
            "role" => [{"value" => "publisher"}],
            "type" => "organization"
          },
          # from druid:kj040zn0537
          {
            "type" => "person",
            "name" => [
              {
                "structuredValue" => [
                  {"value" => "Lasinio, Carlo", "type" => "name"},
                  {"value" => "1759-1838", "type" => "life dates"}
                ]
              }
            ],
            "status" => "primary",
            "role" => [
              {"code" => "egr", "source" => {"code" => "marcrelator"}}
            ]
          }
        ]
      end
      it "returns an array of DisplayValue objects" do
        expect(result).to contain_exactly(
          be_a(CocinaDisplay::DisplayData).and(
            have_attributes(label: "Author", values: ["Doe, John"])
          ),
          be_a(CocinaDisplay::DisplayData).and(
            have_attributes(label: "Editor", values: ["Smith, Jane"])
          ),
          be_a(CocinaDisplay::DisplayData).and(
            have_attributes(label: "Engraver", values: ["Lasinio, Carlo, 1759-1838"])
          )
        )
      end
    end

    context "with no contributors" do
      let(:contributors) { [] }

      it { is_expected.to be_empty }
    end

    context "when contributor has no declared role" do
      let(:contributors) do
        [
          # from druid:bb737zp0787
          {
            "type" => "person",
            "name" => [
              {
                "structuredValue" => [
                  {"value" => "Paget, Francis Edward", "type" => "name"},
                  {"value" => "1759-1838", "type" => "life dates"}
                ]
              }
            ],
            "status" => "primary",
            "role" => []
          }
        ]
      end

      it 'gives a label of "associated with"' do
        expect(result).to contain_exactly(
          be_a(CocinaDisplay::DisplayData).and(
            have_attributes(label: "Associated with", values: ["Paget, Francis Edward, 1759-1838"])
          )
        )
      end
    end

    context "with contributors with parallel names" do
      let(:display_data_hash) { CocinaDisplay::DisplayData.to_hash(result) }

      # adapted from druid:bb070yy8209
      let(:contributors) do
        [
          {
            "name" => [
              {
                "parallelValue" => [
                  {
                    "value" => "صباح، 1927-2014",
                    "status" => "primary"
                  },
                  {
                    "value" => "Ṣabāḥ, 1927-2014",
                    "type" => "transliteration"
                  }
                ]
              }
            ],
            "type" => "person",
            "status" => "primary",
            "role" => [{"value" => "actor"}]
          },
          {
            "name" => [
              {
                "parallelValue" => [
                  {"value" => "ذو الفقار، محمود"},
                  {"value" => "Dhū al-Fiqār, Maḥmūd"}
                ]
              }
            ],
            "type" => "person",
            "role" => [{"value" => "director"}]
          }
        ]
      end

      it "returns display data using the primary name as value" do
        expect(display_data_hash).to eq(
          {
            "Actor" => ["صباح، 1927-2014"],
            "Director" => ["ذو الفقار، محمود"]
          }
        )
      end
    end
  end

  describe "#publisher_names" do
    subject { record.publisher_names }

    context "with publisher contributors" do
      let(:contributors) do
        [
          {
            "name" => [{"value" => "ACME Publishing"}],
            "role" => [{"value" => "publisher"}],
            "type" => "organization"
          },
          {
            "name" => [{"value" => "Smith, Jane"}],
            "role" => [{"value" => "author"}],
            "type" => "person"
          }
        ]
      end

      it { is_expected.to eq(["ACME Publishing"]) }
    end

    context "with no publisher contributors" do
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

    context "with publication event contributors" do
      let(:cocina_json) do
        {
          "description" => {
            "event" => [
              {
                "type" => "publication",
                "contributor" => [
                  {
                    "name" => [{"value" => "Chronicle Books"}],
                    "role" => [{"value" => "publisher"}]
                  }
                ]
              }
            ]
          }
        }.to_json
      end

      it "does not use the event contributor" do
        is_expected.to be_empty
      end
    end
  end

  describe "#author_names" do
    subject { record.author_names }

    context "with author contributors" do
      let(:contributors) do
        [
          {
            "name" => [{"value" => "Doe, John"}],
            "role" => [{"value" => "author"}],
            "type" => "person"
          },
          {
            "name" => [{"value" => "John Smith"}],
            "role" => [{"code" => "aut", "source" => {"code" => "marcrelator"}}],
            "type" => "person"
          },
          {
            "name" => [{"value" => "Smith, Jane"}],
            "role" => [{"value" => "editor"}],
            "type" => "person"
          }
        ]
      end
      it { is_expected.to eq(["Doe, John", "John Smith"]) }
    end

    context "with no author contributors" do
      let(:contributors) do
        [
          {
            "name" => [{"value" => "ACME Corp"}],
            "role" => [{"value" => "publisher"}],
            "type" => "organization"
          }
        ]
      end

      it { is_expected.to be_empty }
    end
  end

  describe "contributor ORCIDs and affiliations" do
    # from druid:cz537wr8540
    let(:cocina_json) do
      {
        "description" => {
          "contributor" => [
            # simple name; no ORCID; no affiliations
            {
              "name" => [{"value" => "ACME Corp"}],
              "type" => "organization",
              "identifier" => [{"value" => "http://id.loc.gov/authorities/names/n79021164", "type" => "LCCN"}],
              "affiliation" => []
            },
            # simple name; ORCID without URI; one simple affiliation with no ROR
            {
              "name" => [{"value" => "John Smith"}],
              "type" => "person",
              "identifier" => [
                {"value" => "0000-0003-1234-5678", "type" => "ORCID"}
              ],
              "affiliation" => [
                {
                  "value" => "Some Institution"
                }
              ]
            },
            # structured name; multiple structured affiliations; same ROR 2 ways
            {
              "name" => [
                {
                  "structuredValue" => [
                    {"value" => "Sayak", "type" => "forename"},
                    {"value" => "Ghosh", "type" => "surname"}
                  ]
                }
              ],
              "type" => "person",
              "identifier" => [
                {"value" => "https://orcid.org/0000-0003-4168-7198", "type" => "ORCID"}
              ],
              "affiliation" => [
                {
                  "structuredValue" => [
                    {
                      "value" => "Stanford University",
                      "identifier" => [
                        {"type" => "ROR", "uri" => "https://ror.org/00f54p054"}
                      ]
                    },
                    {"value" => "Geballe Laboratory for Advanced Materials"}
                  ]
                },
                {
                  "structuredValue" => [
                    {
                      "value" => "Stanford University",
                      "identifier" => [
                        {"type" => "ROR", "value" => "00f54p054"}
                      ]
                    },
                    {"value" => "Department of Applied Physics"}
                  ]
                }
              ]
            }
          ]
        }
      }.to_json
    end

    # Create data structure for checking ORCIDs and affiliations with RORs
    subject(:affiliation_data) do
      record.contributors.map do |contributor|
        {
          name: contributor.to_s,
          orcid: (contributor.orcid if contributor.orcid?),
          orcid_id: (contributor.orcid_id if contributor.orcid?),
          affiliations: contributor.affiliations.map do |affiliation|
            {
              name: affiliation.to_s,
              ror: (affiliation.ror if affiliation.ror?),
              ror_id: (affiliation.ror_id if affiliation.ror?)
            }.compact_blank
          end.compact_blank
        }.compact_blank
      end
    end

    it "returns expected ORCIDs and affiliations with RORs" do
      is_expected.to eq(
        [
          {
            name: "ACME Corp"
          },
          {
            name: "John Smith",
            orcid: "https://orcid.org/0000-0003-1234-5678",
            orcid_id: "0000-0003-1234-5678",
            affiliations: [
              {name: "Some Institution"}
            ]
          },
          {
            name: "Ghosh, Sayak",
            orcid: "https://orcid.org/0000-0003-4168-7198",
            orcid_id: "0000-0003-4168-7198",
            affiliations: [
              {name: "Stanford University, Geballe Laboratory for Advanced Materials", ror: "https://ror.org/00f54p054", ror_id: "00f54p054"},
              {name: "Stanford University, Department of Applied Physics", ror: "https://ror.org/00f54p054", ror_id: "00f54p054"}
            ]
          }
        ]
      )
    end
  end
end
