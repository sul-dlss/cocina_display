require "spec_helper"

RSpec.describe CocinaDisplay::CocinaRecord do
  let(:titles) { [] }
  let(:part_label) { nil }
  let(:cocina_doc) do
    {
      "description" => {
        "title" => titles
      },
      "identification" => {
        "catalogLinks" => [
          {"catalog" => "folio", "partLabel" => part_label}
        ]
      }
    }
  end

  # can this happen? oh well, we handle it anyway
  context "with no titles" do
    describe "#short_title" do
      subject { described_class.new(cocina_doc).short_title }
      it { is_expected.to be_nil }
    end

    describe "#full_title" do
      subject { described_class.new(cocina_doc).full_title }
      it { is_expected.to be_nil }
    end

    describe "#display_title" do
      subject { described_class.new(cocina_doc).display_title }
      it { is_expected.to be_nil }
    end

    describe "#sort_title" do
      subject { described_class.new(cocina_doc).sort_title }
      it { is_expected.to eq "\u{10FFFF}" }
    end

    describe "#title_display_data" do
      subject { described_class.new(cocina_doc).title_display_data }
      it { is_expected.to be_empty }
    end
  end

  # druid:vk217bh4910
  context "with a single untyped title" do
    let(:titles) do
      [
        {"value" => "2010 Machine Learning Data Set for NASA's Solar Dynamics Observatory - Atmospheric Imaging Assembly"}
      ]
    end

    describe "#short_title" do
      subject { described_class.new(cocina_doc).short_title }
      it { is_expected.to eq "2010 Machine Learning Data Set for NASA's Solar Dynamics Observatory - Atmospheric Imaging Assembly" }
    end

    describe "#full_title" do
      subject { described_class.new(cocina_doc).full_title }
      it { is_expected.to eq "2010 Machine Learning Data Set for NASA's Solar Dynamics Observatory - Atmospheric Imaging Assembly." }
    end

    describe "#display_title" do
      subject { described_class.new(cocina_doc).display_title }
      it { is_expected.to eq "2010 Machine Learning Data Set for NASA's Solar Dynamics Observatory - Atmospheric Imaging Assembly" }
    end

    describe "#sort_title" do
      subject { described_class.new(cocina_doc).sort_title }
      it { is_expected.to eq "2010 Machine Learning Data Set for NASAs Solar Dynamics Observatory Atmospheric Imaging Assembly" }
    end

    describe "#additional_titles" do
      subject { described_class.new(cocina_doc).additional_titles }
      it { is_expected.to be_empty }
    end

    describe "#title_display_data" do
      subject do
        described_class.new(cocina_doc).title_display_data.each_with_object({}) do |display_data, output|
          output[display_data.label] = display_data.values
        end
      end
      it { is_expected.to eq "Title" => ["2010 Machine Learning Data Set for NASA's Solar Dynamics Observatory - Atmospheric Imaging Assembly"] }
    end
  end

  # druid:bx658jh7339
  context "with a structured title" do
    let(:titles) do
      [
        {
          "structuredValue" => [
            {"value" => "M. de Courville", "type" => "main title"},
            {"value" => "[estampe]", "type" => "subtitle"}
          ]
        }
      ]
    end

    describe "#short_title" do
      subject { described_class.new(cocina_doc).short_title }
      it { is_expected.to eq "M. de Courville" }
    end

    describe "#full_title" do
      subject { described_class.new(cocina_doc).full_title }
      it { is_expected.to eq "M. de Courville : [estampe]" }
    end

    describe "#display_title" do
      subject { described_class.new(cocina_doc).display_title }
      it { is_expected.to eq "M. de Courville : [estampe]" }
    end

    describe "#sort_title" do
      subject { described_class.new(cocina_doc).sort_title }
      it { is_expected.to eq "M de Courville estampe" }
    end

    describe "#additional_titles" do
      subject { described_class.new(cocina_doc).additional_titles }
      it { is_expected.to be_empty }
    end

    describe "#title_display_data" do
      subject do
        described_class.new(cocina_doc).title_display_data.each_with_object({}) do |display_data, output|
          output[display_data.label] = display_data.values
        end
      end
      it { is_expected.to eq "Title" => ["M. de Courville : [estampe]"] }
    end
  end

  # druid:wb133vg3886
  context "with nonsorting characters and subtitle" do
    let(:titles) do
      [
        {
          "structuredValue" => [
            {"value" => "The", "type" => "nonsorting characters"},
            {"value" => "Ingersoll-Gladstone controversy on Christianity", "type" => "main title"},
            {"value" => "two articles from the North American review", "type" => "subtitle"}
          ],
          "note" => [
            {"value" => "4", "type" => "nonsorting character count"}
          ]
        }
      ]
    end

    describe "#short_title" do
      subject { described_class.new(cocina_doc).short_title }
      it { is_expected.to eq "The Ingersoll-Gladstone controversy on Christianity" }
    end

    describe "#full_title" do
      subject { described_class.new(cocina_doc).full_title }
      it { is_expected.to eq "The Ingersoll-Gladstone controversy on Christianity : two articles from the North American review." }
    end

    describe "#display_title" do
      subject { described_class.new(cocina_doc).display_title }
      it { is_expected.to eq "The Ingersoll-Gladstone controversy on Christianity : two articles from the North American review" }
    end

    describe "#sort_title" do
      subject { described_class.new(cocina_doc).sort_title }
      it { is_expected.to eq "IngersollGladstone controversy on Christianity two articles from the North American review" }
    end

    describe "#additional_titles" do
      subject { described_class.new(cocina_doc).additional_titles }
      it { is_expected.to be_empty }
    end

    describe "#title_display_data" do
      subject do
        described_class.new(cocina_doc).title_display_data.each_with_object({}) do |display_data, output|
          output[display_data.label] = display_data.values
        end
      end
      it { is_expected.to eq "Title" => ["The Ingersoll-Gladstone controversy on Christianity : two articles from the North American review"] }
    end
  end

  # druid:sw705fr7011
  context "with part number and nonsorting characters" do
    let(:titles) do
      [
        {
          "structuredValue" => [
            {"value" => "Oral history interview with", "type" => "nonsorting characters"},
            {"value" => "anonymous, white, female, SNCC volunteer, 0405 (sides 1 and 2), Laurel, Mississippi", "type" => "main title"},
            {"value" => "0405", "type" => "part number"}
          ],
          "note" => [
            {"value" => "28", "type" => "nonsorting character count"}
          ]
        }
      ]
    end

    describe "#short_title" do
      subject { described_class.new(cocina_doc).short_title }
      it { is_expected.to eq "Oral history interview with anonymous, white, female, SNCC volunteer, 0405 (sides 1 and 2), Laurel, Mississippi" }
    end

    describe "#full_title" do
      subject { described_class.new(cocina_doc).full_title }
      it { is_expected.to eq "Oral history interview with anonymous, white, female, SNCC volunteer, 0405 (sides 1 and 2), Laurel, Mississippi. 0405." }
    end

    describe "#display_title" do
      subject { described_class.new(cocina_doc).display_title }
      it { is_expected.to eq "Oral history interview with anonymous, white, female, SNCC volunteer, 0405 (sides 1 and 2), Laurel, Mississippi. 0405" }
    end

    describe "#sort_title" do
      subject { described_class.new(cocina_doc).sort_title }
      it { is_expected.to eq "anonymous white female SNCC volunteer 0405 sides 1 and 2 Laurel Mississippi 0405" }
    end

    describe "#additional_titles" do
      subject { described_class.new(cocina_doc).additional_titles }
      it { is_expected.to be_empty }
    end

    describe "#title_display_data" do
      subject do
        described_class.new(cocina_doc).title_display_data.each_with_object({}) do |display_data, output|
          output[display_data.label] = display_data.values
        end
      end
      it { is_expected.to eq "Title" => ["Oral history interview with anonymous, white, female, SNCC volunteer, 0405 (sides 1 and 2), Laurel, Mississippi. 0405"] }
    end
  end

  # druid:sm324fc8745
  context "with multiple parallel titles and uniform title with name" do
    let(:titles) do
      [
        {
          "parallelValue" => [
            {"value" => "Teshuvot she'ilot"},
            {"value" => "תשובות שאילות"}
          ]
        },
        {
          "parallelValue" => [
            {"value" => "Teshuvot ha-Rashba ha-meyuḥasot leha-Ramban", "type" => "alternative"},
            {"value" => "תשובות הרשב׳׳א המיוחסות להרמב׳׳ן", "type" => "alternative"}
          ]
        },
        {
          "value" => "Teshuvot sheʼelot",
          "type" => "uniform",
          "note" => [
            {
              "structuredValue" => [
                {"value" => "Adret, Solomon ben Abraham", "type" => "name"},
                {"value" => "1235-1310", "type" => "life dates"}
              ],
              "type" => "associated name"
            }
          ]
        }
      ]
    end

    describe "#short_title" do
      subject { described_class.new(cocina_doc).short_title }
      it { is_expected.to eq "Teshuvot she'ilot" } # first parallel of primary (first untyped) title
    end

    describe "#full_title" do
      subject { described_class.new(cocina_doc).full_title }
      it { is_expected.to eq "Teshuvot she'ilot." }
    end

    describe "#display_title" do
      subject { described_class.new(cocina_doc).display_title }
      it { is_expected.to eq "Teshuvot she'ilot" }
    end

    describe "#sort_title" do
      subject { described_class.new(cocina_doc).sort_title }
      it { is_expected.to eq "Teshuvot sheilot" }
    end

    describe "#additional_titles" do
      subject { described_class.new(cocina_doc).additional_titles }
      it do
        is_expected.to eq [
          "תשובות שאילות", # parallel of primary title
          "Teshuvot ha-Rashba ha-meyuḥasot leha-Ramban", # first parallel of alternative title
          "תשובות הרשב׳׳א המיוחסות להרמב׳׳ן", # second parallel of alternative title
          "Adret, Solomon ben Abraham, 1235-1310. Teshuvot sheʼelot" # uniform title with name
        ]
      end
    end

    describe "#title_display_data" do
      subject do
        described_class.new(cocina_doc).title_display_data.each_with_object({}) do |display_data, output|
          output[display_data.label] = display_data.values
        end
      end

      it do
        is_expected.to eq(
          "Title" => [
            "Teshuvot she'ilot",
            "תשובות שאילות"
          ],
          "Alternative title" => [
            "Teshuvot ha-Rashba ha-meyuḥasot leha-Ramban",
            "תשובות הרשב׳׳א המיוחסות להרמב׳׳ן"
          ],
          "Uniform title" => ["Adret, Solomon ben Abraham, 1235-1310. Teshuvot sheʼelot"]
        )
      end
    end
  end

  # druid:ym079kd1568
  context "with structured titles with nonsorting characters that should not be padded" do
    let(:titles) do
      [
        {
          "structuredValue" => [
            {"value" => "The", "type" => "nonsorting characters"},
            {"value" => "Child Dreams (1993) revised script", "type" => "main title"}
          ],
          "status" => "primary"
        },
        {
          "parallelValue" => [
            {
              "structuredValue" => [
                {"value" => "ha-", "type" => "nonsorting characters"},
                {"value" => "Yeled ḥalom ", "type" => "main title"},
                {"value" => "maḥazeh be-arbaʻah ḥalaḳim ", "type" => "subtitle"}
              ],
              "type" => "transliterated"
            },
            {
              "structuredValue" => [
                {"value" => "ה", "type" => "nonsorting characters"},
                {"value" => "ילד חלום", "type" => "main title"},
                {"value" => "מחזה בארבעה חלקים", "type" => "subtitle"}
              ],
              "type" => "alternative"
            },
            {
              "structuredValue" => [
                {"value" => "The ", "type" => "nonsorting characters"},
                {"value" => "Child Dreams", "type" => "main title"},
                {"value" => "play in four parts", "type" => "subtitle"}
              ],
              "type" => "translated"
            }
          ]
        }
      ]
    end

    describe "#short_title" do
      subject { described_class.new(cocina_doc).short_title }
      it { is_expected.to eq "The Child Dreams (1993) revised script" } # primary title
    end

    describe "#full_title" do
      subject { described_class.new(cocina_doc).full_title }
      it { is_expected.to eq "The Child Dreams (1993) revised script." }
    end

    describe "#display_title" do
      subject { described_class.new(cocina_doc).display_title }
      it { is_expected.to eq "The Child Dreams (1993) revised script" }
    end

    describe "#sort_title" do
      subject { described_class.new(cocina_doc).sort_title }
      it { is_expected.to eq "Child Dreams 1993 revised script" }
    end

    describe "#additional_titles" do
      subject { described_class.new(cocina_doc).additional_titles }
      it do
        is_expected.to eq [
          "ha-Yeled ḥalom : maḥazeh be-arbaʻah ḥalaḳim", # transliterated
          "הילד חלום : מחזה בארבעה חלקים", # alternative
          "The Child Dreams : play in four parts" # translated
        ]
      end
    end

    describe "#title_display_data" do
      subject { CocinaDisplay::DisplayData.to_hash(described_class.new(cocina_doc).title_display_data) }

      it do
        is_expected.to eq(
          "Title" => ["The Child Dreams (1993) revised script"],
          "Transliterated title" => ["ha-Yeled ḥalom : maḥazeh be-arbaʻah ḥalaḳim"],
          "Alternative title" => ["הילד חלום : מחזה בארבעה חלקים"],
          "Translated title" => ["The Child Dreams : play in four parts"]
        )
      end
    end
  end

  # druid:bb022pc9382
  context "with parallel main, alternative, and uniform titles" do
    let(:titles) do
      [
        {
          "parallelValue" => [
            {
              "structuredValue" => [
                {"value" => "Sefer Bet nadiv", "type" => "main title"},
                {"value" => "sheʼelot u-teshuvot, ḥidushe Torah, derashot", "type" => "subtitle"}
              ],
              "status" => "primary"
            },
            {
              "structuredValue" => [
                {"value" => "ספר בית נדיב", "type" => "main title"},
                {"value" => "שאלות ותשובות, חידושי תורה, דרשות", "type" => "subtitle"}
              ]
            }
          ]
        },
        {
          "parallelValue" => [
            {
              "value" => "Bet nadiv",
              "note" => [
                {
                  "structuredValue" => [
                    {"value" => "Leṿin, Natan", "type" => "name"},
                    {"value" => "1856 or 1857-1926", "type" => "life dates"}
                  ],
                  "type" => "associated name"
                }
              ]
            },
            {
              "value" => "בית נדיב",
              "note" => [
                {
                  "value" => "לוין, נתן",
                  "type" => "associated name"
                }
              ]
            }
          ],
          "type" => "uniform"
        },
        {
          "parallelValue" => [
            {"value" => "Bet nadiv", "type" => "alternative"},
            {"value" => "בית נדיב", "type" => "alternative"}
          ]
        }
      ]
    end

    describe "#short_title" do
      subject { described_class.new(cocina_doc).short_title }
      it { is_expected.to eq "Sefer Bet nadiv" } # parallel marked as primary
    end

    describe "#full_title" do
      subject { described_class.new(cocina_doc).full_title }
      it { is_expected.to eq "Sefer Bet nadiv : sheʼelot u-teshuvot, ḥidushe Torah, derashot." }
    end

    describe "#display_title" do
      subject { described_class.new(cocina_doc).display_title }
      it { is_expected.to eq "Sefer Bet nadiv : sheʼelot u-teshuvot, ḥidushe Torah, derashot" }
    end

    describe "#sort_title" do
      subject { described_class.new(cocina_doc).sort_title }
      it { is_expected.to eq "Sefer Bet nadiv sheʼelot uteshuvot ḥidushe Torah derashot" }
    end

    describe "#additional_titles" do
      subject { described_class.new(cocina_doc).additional_titles }
      it do
        is_expected.to eq [
          "ספר בית נדיב : שאלות ותשובות, חידושי תורה, דרשות", # parallel of primary title
          "Leṿin, Natan, 1856 or 1857-1926. Bet nadiv", # first parallel of uniform title
          "לוין, נתן. בית נדיב", # second parallel of uniform title
          "Bet nadiv", # first parallel of alternative title
          "בית נדיב" # second parallel of alternative title
        ]
      end
    end

    describe "#title_display_data" do
      subject do
        described_class.new(cocina_doc).title_display_data.each_with_object({}) do |display_data, output|
          output[display_data.label] = display_data.values
        end
      end

      it do
        is_expected.to eq(
          "Title" => [
            "Sefer Bet nadiv : sheʼelot u-teshuvot, ḥidushe Torah, derashot",
            "ספר בית נדיב : שאלות ותשובות, חידושי תורה, דרשות"  # parallel *is* included here
          ],
          "Uniform title" => [
            "Leṿin, Natan, 1856 or 1857-1926. Bet nadiv",
            "לוין, נתן. בית נדיב"
          ],
          "Alternative title" => [
            "Bet nadiv",
            "בית נדיב"
          ]
        )
      end
    end
  end

  # druid:jt959wc5586
  context "with a digital serial with part label from the catalog" do
    let(:titles) do
      [
        {
          "structuredValue" => [
            {"value" => "Archives parlementaires de 1787 à 1860", "type" => "main title"},
            {"value" => "recueil complet des débats législatifs & politiques des chambres françaises imprimé par ordre du Sénat et de la Chambre des députés sous la direction de m. J. Mavidal ... et de m. E. Laurent", "type" => "subtitle"}
          ],
          "status" => "primary"
        },
        {"value" => "Archives parlementaires", "type" => "alternative"}
      ]
    end
    let(:part_label) { "Series 1, Volume 1" }

    describe "#short_title" do
      subject { described_class.new(cocina_doc).short_title }
      it { is_expected.to eq "Archives parlementaires de 1787 à 1860" }
    end

    describe "#full_title" do
      subject { described_class.new(cocina_doc).full_title }
      it { is_expected.to eq "Archives parlementaires de 1787 à 1860 : recueil complet des débats législatifs & politiques des chambres françaises imprimé par ordre du Sénat et de la Chambre des députés sous la direction de m. J. Mavidal ... et de m. E. Laurent. Series 1, Volume 1." }
    end

    describe "#display_title" do
      subject { described_class.new(cocina_doc).display_title }
      it { is_expected.to eq "Archives parlementaires de 1787 à 1860 : recueil complet des débats législatifs & politiques des chambres françaises imprimé par ordre du Sénat et de la Chambre des députés sous la direction de m. J. Mavidal ... et de m. E. Laurent. Series 1, Volume 1" }
    end

    describe "#sort_title" do
      subject { described_class.new(cocina_doc).sort_title }
      it { is_expected.to eq "Archives parlementaires de 1787 a 1860 recueil complet des débats législatifs politiques des chambres françaises imprime par ordre du Sénat et de la Chambre des députés sous la direction de m J Mavidal et de m E Laurent Series 1 Volume 1" }
    end

    describe "#additional_titles" do
      subject { described_class.new(cocina_doc).additional_titles }
      it { is_expected.to eq ["Archives parlementaires. Series 1, Volume 1"] }
    end

    describe "#title_display_data" do
      subject do
        described_class.new(cocina_doc).title_display_data.each_with_object({}) do |display_data, output|
          output[display_data.label] = display_data.values
        end
      end

      it do
        is_expected.to eq(
          "Title" => ["Archives parlementaires de 1787 à 1860 : recueil complet des débats législatifs & politiques des chambres françaises imprimé par ordre du Sénat et de la Chambre des députés sous la direction de m. J. Mavidal ... et de m. E. Laurent. Series 1, Volume 1"],
          "Alternative title" => ["Archives parlementaires. Series 1, Volume 1"]
        )
      end
    end
  end

  # druid:kf879tn8532
  context "with a title that duplicates part label in the primary title" do
    let(:titles) do
      [
        {"value" => "Mehmet Sadik Rifat Pasha's Risale-i ahlak", "status" => "primary"},
        {"value" => "Risale-i ahlak", "type" => "alternative"},
        {"value" => "Risâle-yi ahlâk. Ladino",
         "type" => "uniform",
         "uri" => "http://id.loc.gov/authorities/names/n2003060121",
         "note" => [
           {
             "structuredValue" => [
               {"value" => "Rifat Paşa, Mehmet Sadık", "type" => "name"},
               {"value" => "1807-1856", "type" => "life dates"}
             ],
             "type" => "associated name"
           }
         ]}
      ]
    end
    let(:part_label) { "Risale-i ahlak" }

    describe "#short_title" do
      subject { described_class.new(cocina_doc).short_title }
      it { is_expected.to eq "Mehmet Sadik Rifat Pasha's Risale-i ahlak" }
    end

    describe "#full_title" do
      subject { described_class.new(cocina_doc).full_title }
      it { is_expected.to eq "Mehmet Sadik Rifat Pasha's Risale-i ahlak." }
    end

    describe "#display_title" do
      subject { described_class.new(cocina_doc).display_title }
      it { is_expected.to eq "Mehmet Sadik Rifat Pasha's Risale-i ahlak" }
    end

    describe "#sort_title" do
      subject { described_class.new(cocina_doc).sort_title }
      it { is_expected.to eq "Mehmet Sadik Rifat Pashas Risalei ahlak" }
    end

    describe "#additional_titles" do
      subject { described_class.new(cocina_doc).additional_titles }
      it do
        is_expected.to eq [
          # alternative title
          "Risale-i ahlak",
          # it would be nice if we could prevent duplication here, but tough to detect it...
          "Rifat Paşa, Mehmet Sadık, 1807-1856. Risâle-yi ahlâk. Ladino. Risale-i ahlak"
        ]
      end
    end
  end
end
