# frozen_string_literal: true

require "spec_helper"

RSpec.describe CocinaDisplay::Events::Event do
  subject(:event) { described_class.new(cocina) }

  describe "#dates" do
    subject(:dates) { event.dates }

    # See also https://github.com/sul-dlss/cocina-models/issues/830
    context "with missing date value (as seen in wf027xk3554)" do
      before do
        allow(CocinaDisplay).to receive(:notifier).and_return(notifier)
      end

      let(:notifier) { double(:notifier, notify: nil) }

      let(:cocina) do
        {
          "date" => [
            {
              "encoding" => {
                "code" => "marc"
              }
            }
          ],
          "type" => "creation"
        }
      end

      it "removes the invalid date values" do
        expect(dates).to eq []
        expect(notifier).not_to have_received(:notify).with("Invalid date value")
      end
    end
  end
end
