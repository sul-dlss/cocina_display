require "spec_helper"

RSpec.describe CocinaDisplay::CocinaRecord do
  describe "#main_title" do
    context "with fixture data" do
      let(:cocina_json) { File.read(file_fixture("#{druid}.json")) }
      let(:cocina_doc) { JSON.parse(cocina_json) }

      subject { described_class.from_json(cocina_json).main_title }

      context "with nonsorting characters" do
        let(:druid) { "bt553vr2845" }

        it "does not add any padding" do
          is_expected.to eq "The master and Margarita"
        end
      end

      context "with a subtitle" do
        let(:druid) { "bx658jh7339" }

        it "returns the title formatted without the subtitle" do
          is_expected.to eq "M. de Courville"
        end
      end

      context "with escaped characters" do
        let(:druid) { "bb112zx3193" }

        it "renders the title correctly" do
          is_expected.to eq "Bugatti Type 51A. Road & Track Salon January 1957"
        end
      end
    end
  end

  describe "#full_title" do
    context "with fixture data" do
      let(:cocina_json) { File.read(file_fixture("#{druid}.json")) }
      let(:cocina_doc) { JSON.parse(cocina_json) }

      subject { described_class.from_json(cocina_json).full_title }

      context "with nonsorting characters" do
        let(:druid) { "bt553vr2845" }

        it "adds the specified nonsorting padding" do
          is_expected.to eq "The  master and Margarita"
        end
      end

      context "with a subtitle" do
        let(:druid) { "bx658jh7339" }

        it "returns the full title with subtitle but no punctuation" do
          is_expected.to eq "M. de Courville [estampe]"
        end
      end
    end
  end

  describe "#display_title" do
    context "with fixture data" do
      let(:cocina_json) { File.read(file_fixture("#{druid}.json")) }
      let(:cocina_doc) { JSON.parse(cocina_json) }

      subject { described_class.from_json(cocina_json).display_title }

      context "with nonsorting characters" do
        let(:druid) { "bt553vr2845" }

        it "adds the specified nonsorting padding" do
          is_expected.to eq "The  master and Margarita"
        end
      end

      context "with a subtitle" do
        let(:druid) { "bx658jh7339" }

        it "returns the title with subtitle and punctuation" do
          is_expected.to eq "M. de Courville : [estampe]"
        end
      end
    end
  end

  describe "#sort_title" do
    context "with fixture data" do
      let(:cocina_json) { File.read(file_fixture("#{druid}.json")) }
      let(:cocina_doc) { JSON.parse(cocina_json) }

      subject { described_class.from_json(cocina_json).sort_title }

      context "with nonsorting characters" do
        let(:druid) { "bt553vr2845" }

        it "returns the title without nonsorting characters" do
          is_expected.to eq "master and Margarita"
        end
      end

      context "with a subtitle" do
        let(:druid) { "bx658jh7339" }

        it "returns the title with subtitle but without punctuation" do
          is_expected.to eq "M de Courville estampe"
        end
      end

      context "with a title containing punctuation surrounded by spaces" do
        let(:druid) { "vk217bh4910" }

        it "returns the sort title without duplicate spaces" do
          is_expected.to eq "2010 Machine Learning Data Set for NASAs Solar Dynamics Observatory Atmospheric Imaging Assembly"
        end
      end
    end

    context "with no title" do
      let(:cocina_doc) { {"description" => {"title" => []}} }
      let(:cocina_json) { cocina_doc.to_json }

      subject { described_class.from_json(cocina_json).sort_title }

      it "returns the placeholder that sorts last" do
        is_expected.to eq "\u{10FFFF}"
      end
    end
  end

  describe "#additional_titles" do
    context "with fixture data" do
      let(:cocina_json) { File.read(file_fixture("#{druid}.json")) }
      let(:cocina_doc) { JSON.parse(cocina_json) }

      subject { described_class.from_json(cocina_json).additional_titles }

      context "with an alternative title" do
        let(:druid) { "nz187ct8959" }

        it "returns the alternative title" do
          is_expected.to eq ["Two thousand and ten China province population census data with GIS maps"]
        end
      end

      context "with a parallel translated title" do
        let(:druid) { "bt553vr2845" }

        it "returns the parallel title" do
          is_expected.to eq ["Master i Margarita. English"]
        end
      end
    end
  end
end
