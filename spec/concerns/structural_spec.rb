# frozen_string_literal: true

require "spec_helper"

RSpec.describe CocinaDisplay::CocinaRecord do
  let(:druid) { "bb099mt5053" }
  let(:cocina_json) { File.read(file_fixture("#{druid}.json")) }
  let(:cocina_doc) { JSON.parse(cocina_json) }

  subject { described_class.new(cocina_doc) }

  describe "#files" do
    it "returns an array of file objects" do
      expect(subject.files.first.filename).to eq("bb099mt5053_sl.m4a")
      expect(subject.files.first.size).to eq(13832365)
    end
  end

  describe "#file_mime_types" do
    it "returns an array of unique MIME types" do
      expect(subject.file_mime_types).to contain_exactly("audio/mp4", "image/jp2")
    end
  end

  describe "#fileset_types" do
    it "returns an array of unique fileset types" do
      expect(subject.fileset_types).to contain_exactly("audio", "image")
    end
  end

  describe "#total_file_size_str" do
    it "returns a human-readable string representation of the total file size" do
      expect(subject.total_file_size_str).to eq("14.1 MB")
    end
  end

  describe "#total_file_size_int" do
    it "returns the total file size in bytes" do
      expect(subject.total_file_size_int).to eq(14744206)
    end
  end

  describe "#thumbnail_url" do
    context "when there is a file marked for thumbnail use" do
      let(:druid) { "bc798xr9549" }

      it "returns the thumbnail file" do
        expect(subject.thumbnail_url).to eq("https://stacks.stanford.edu/image/iiif/bc798xr9549%2Fbc798xr9549_30C_Kalsang_Yulgial_thumb/full/!400,400/0/default.jpg")
      end

      it "allows optional parameters for region, width, and height" do
        expect(subject.thumbnail_url(region: "square", width: "200", height: "200")).to eq("https://stacks.stanford.edu/image/iiif/bc798xr9549%2Fbc798xr9549_30C_Kalsang_Yulgial_thumb/square/200,200/0/default.jpg")
      end
    end

    context "when there is no marked file, but there are jp2 images" do
      let(:druid) { "bk264hq9320" }

      it "returns the first jp2 image file" do
        expect(subject.thumbnail_url).to eq("https://stacks.stanford.edu/image/iiif/bk264hq9320%2Fbk264hq9320_img_1/full/!400,400/0/default.jpg")
      end
    end

    context "when there is an image but it has zero dimensions" do
      let(:cocina_doc) do
        {
          "structural" => {
            "contains" => [
              {
                "type" => "https://cocina.sul.stanford.edu/models/resources/image",
                "structural" => {
                  "contains" => [
                    {
                      "filename" => "zero_dim_image.jp2",
                      "hasMimeType" => "image/jp2",
                      "presentation" => {
                        "height" => 0,
                        "width" => 0
                      },
                      "size" => 204800
                    }
                  ]
                }
              }
            ]
          }
        }
      end

      it "returns nil" do
        expect(subject.thumbnail_url).to be_nil
      end
    end

    context "with a virtual object (no files)" do
      let(:druid) { "ws947mh3822" }

      it "returns nil" do
        expect(subject.thumbnail_url).to be_nil
      end
    end
  end

  describe "#thumbnail?" do
    context "with images" do
      let(:druid) { "bk264hq9320" }

      it { is_expected.to be_thumbnail }
    end

    context "with no images" do
      let(:druid) { "nz187ct8959" }

      it { is_expected.not_to be_thumbnail }
    end
  end

  describe "#containing_collections" do
    it "returns an array of collection DRUIDs" do
      expect(subject.containing_collections).to contain_exactly("sj775xm6965")
    end

    context "when the object is not a member of any collections" do
      before do
        cocina_doc["structural"].delete("isMemberOf")
      end

      it "returns an empty array" do
        expect(subject.containing_collections).to be_empty
      end
    end
  end

  describe "#virtual_object?" do
    context "when the object is a virtual object" do
      let(:druid) { "ws947mh3822" }

      it "returns true" do
        expect(subject.virtual_object?).to be true
      end
    end

    context "when the object is not a virtual object" do
      it "returns false" do
        expect(subject.virtual_object?).to be false
      end
    end
  end

  describe "#virtual_object_members" do
    context "when the object is a virtual object" do
      let(:druid) { "ws947mh3822" }

      it "returns an array of member DRUIDs" do
        expect(subject.virtual_object_members).to contain_exactly("ts786ny5936", "tp006ms8736", "tj297ys4758")
      end
    end

    context "when the object is not a virtual object" do
      it "returns an empty array" do
        expect(subject.virtual_object_members).to be_empty
      end
    end
  end

  describe "#virtual_object_parents" do
    context "when the object is part of virtual objects" do
      let(:druid) { "fn851zf9475" }

      it "returns an array of parent virtual object DRUIDs" do
        expect(subject.virtual_object_parents).to contain_exactly("dg050kz7339")
      end
    end

    context "when the object is not part of any virtual objects" do
      let(:druid) { "bb099mt5053" }

      it "returns an empty array" do
        expect(subject.virtual_object_parents).to be_empty
      end
    end
  end

  context "with a staging object" do
    let(:druid) { "bh114dk3076" }

    it "generates file download URLs from stacks staging environment" do
      expect(subject.files.first.download_url).to eq("https://sul-stacks-stage.stanford.edu/file/druid:bh114dk3076/README.md")
    end
  end
end
