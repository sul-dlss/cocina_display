module CocinaDisplay
  class Access
    def initialize(json)
      @json = json
    end

    attr_reader :json

    def use_and_reproduction
      json.dig("useAndReproductionStatement")
    end

    def copyright
      json.dig("copyright")
    end
  end
end
