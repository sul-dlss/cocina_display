require "spec_helper"

RSpec.describe CocinaDisplay::Structural::File do
  subject { described_class.new(cocina) }

  describe "#download_url" do
    let(:cocina) do
      {
        "externalIdentifier" => "https://cocina.sul.stanford.edu/file/bc798xr9549-bc798xr9549_3/bc798xr9549_30C_Kalsang_Yulgial_img.jp2",
        "filename" => "bc798xr9549_30C_Kalsang_Yulgial_img.jp2"
      }
    end

    it "generates a download URL for the file" do
      expect(subject.download_url).to eq("https://stacks.stanford.edu/file/druid:bc798xr9549/bc798xr9549_30C_Kalsang_Yulgial_img.jp2")
    end
  end

  describe "#iiif_url" do
    context "with a jp2 image with height and width" do
      let(:cocina) do
        {
          "type" => "https://cocina.sul.stanford.edu/models/file",
          "externalIdentifier" => "https://cocina.sul.stanford.edu/file/bc798xr9549-bc798xr9549_3/bc798xr9549_30C_Kalsang_Yulgial_img.jp2",
          "hasMimeType" => "image/jp2",
          "filename" => "bc798xr9549_30C_Kalsang_Yulgial_img.jp2",
          "presentation" => {
            "height" => 2100,
            "width" => 1500
          }
        }
      end

      it "generates a IIIF image URL for the file" do
        expect(subject.iiif_url).to eq("https://stacks.stanford.edu/image/iiif/bc798xr9549%2Fbc798xr9549_30C_Kalsang_Yulgial_img/full/!400,400/0/default.jpg")
      end
    end

    context "with a non-jp2 file" do
      let(:cocina) do
        {
          "type" => "https://cocina.sul.stanford.edu/models/file",
          "externalIdentifier" => "https://cocina.sul.stanford.edu/file/bc798xr9549-bc798xr9549_3/bc798xr9549_30C_Kalsang_Yulgial_img.jpg",
          "filename" => "bc798xr9549_30C_Kalsang_Yulgial_img.jpg",
          "hasMimeType" => "image/jpeg",
          "presentation" => {
            "height" => 2100,
            "width" => 1500
          }
        }
      end

      it "returns nil" do
        expect(subject.iiif_url).to be_nil
      end
    end

    context "with an image without height or width" do
      let(:cocina) do
        {
          "type" => "https://cocina.sul.stanford.edu/models/file",
          "externalIdentifier" => "https://cocina.sul.stanford.edu/file/bc798xr9549-bc798xr9549_3/bc798xr9549_30C_Kalsang_Yulgial_img.jp2",
          "filename" => "bc798xr9549_30C_Kalsang_Yulgial_img.jp2",
          "hasMimeType" => "image/jp2"
        }
      end

      it "returns nil" do
        expect(subject.iiif_url).to be_nil
      end
    end
  end
end
