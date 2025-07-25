# frozen_string_literal: true

require "active_support"
require "active_support/core_ext/object/blank"
require "active_support/core_ext/string/access"
require "active_support/core_ext/string/starts_ends_with"

module CocinaDisplay
  # Select and format title data as a string for display or indexing.
  class TitleBuilder
    # @param titles [Array<Hash>] The titles to consider.
    # @param catalog_links [Array<Hash>] The folio catalog links to check for digital serials part labels.
    # @param strategy [Symbol] ":first" is the strategy for selection when primary or display title are missing.
    # @param add_punctuation [Boolean] Determines if the title should be formatted with punctuation.
    # @return [String, Array] The title value for Solr - for :first strategy, a string; for :all strategy, an array.
    #   (e.g. title displayed in blacklight search results vs boosting values for search result rankings)
    def self.build(titles, catalog_links: [], strategy: :first, add_punctuation: true)
      part_label = catalog_links.find { |link| link["catalog"] == "folio" }&.fetch("partLabel", nil)
      new(strategy: strategy, add_punctuation: add_punctuation, part_label: part_label).build(titles)
    end

    # the "main title" is the title withOUT subtitle, part name, etc.  We want to index it separately so
    # we can boost matches on it in search results (boost matching this string higher than matching full title string)
    # e.g. "The Hobbit" (main_title) vs "The Hobbit, or, There and Back Again (full_title)
    # @param titles [Array<Hash>] The titles to consider.
    # @return [Array<String>] The main title value(s) for Solr - array due to possible parallelValue
    def self.main_title(titles)
      new(strategy: :first, add_punctuation: false).main_title(titles)
    end

    # the "full title" is the title WITH subtitle, part name, etc.  We want to able able to index it separately so
    # we can boost matches on it in search results (boost matching this string higher than other titles present)
    # @param titles [Array<Hash>] The titles to consider.
    # @param catalog_links [Array<Hash>] The folio catalog links to check for digital serials part labels.
    # @return [Array<String>] The full title value(s) for Solr - array due to possible parallelValue
    def self.full_title(titles, catalog_links: [])
      part_label = catalog_links.find { |link| link["catalog"] == "folio" }&.fetch("partLabel", nil)
      [new(strategy: :first, add_punctuation: false, only_one_parallel_value: false, part_label: part_label).build(titles)].flatten.compact
    end

    # "additional titles" are all title data except for full_title.  We want to able able to index it separately so
    # we can boost matches on it in search results (boost matching these strings lower than other titles present)
    # @param titles [Array<Hash>] The titles to consider.
    # @return [Array<String>] The values for Solr.
    def self.additional_titles(titles)
      [new(strategy: :all, add_punctuation: false).build(titles)].flatten - full_title(titles)
    end

    # Like the full title, but with any non-sorting characters and punctuation removed.
    # @param titles [Array<Hash>] The titles to consider.
    # @param catalog_links [Array<Hash>] The folio catalog links to check for digital serials part labels.
    # @return [Array<String>] The sort title value(s) for Solr - array due to possible parallelValue
    def self.sort_title(titles, catalog_links: [])
      part_label = catalog_links.find { |link| link["catalog"] == "folio" }&.fetch("partLabel", nil)
      [new(strategy: :first, add_punctuation: false, only_one_parallel_value: false, part_label: part_label, sortable: true).build(titles)]
        .flatten.compact.map { |title| title.gsub(/[[:punct:]]*/, "").squeeze(" ").strip }
    end

    # @param strategy [Symbol] ":first" selects a single title value based on precedence of
    # primary, untyped, first occurrence. ":all" returns an array containing all the values.
    # @param add_punctuation [boolean] whether the title should be formatted with punctuation (think of a structured
    # value coming from a MARC record, which is designed for catalog cards.)
    # @param only_one_parallel_value [boolean] when true, choose one of the parallel values according to precedence
    # of primary, untyped, first occurrence.  When false, return an array containing all the parallel values.
    # Why? Think of e.g. title displayed in blacklight search results vs boosting values for ranking of search results
    # @param part_label [String] the partLabel to add for digital serials display
    # @param sortable [boolean] whether the title is intended for sorting, and should have non-sorting parts removed
    def initialize(strategy:, add_punctuation:, only_one_parallel_value: true, part_label: nil, sortable: false)
      @strategy = strategy
      @add_punctuation = add_punctuation
      @only_one_parallel_value = only_one_parallel_value
      @part_label = part_label
      @sortable = sortable
    end

    # @param [Array<Hash>] cocina_titles the titles to consider
    # @return [String, Array] the title value for Solr - for :first strategy, a string; for :all strategy, an array
    # (e.g. title displayed in blacklight search results vs boosting values for search result rankings)
    # rubocop:disable Metrics/PerceivedComplexity
    def build(cocina_titles)
      cocina_title = primary_title(cocina_titles) || untyped_title(cocina_titles)
      cocina_title = other_title(cocina_titles) if cocina_title.blank?
      if strategy == :first
        result = extract_title(cocina_title)
        result = add_part_label(result) if part_label.present?
        result
      else
        result = cocina_titles.map { |ctitle| extract_title(ctitle) }.flatten
        if only_one_parallel_value? && result.length == 1
          result.first
        else
          result
        end
      end
    end
    # rubocop:enable Metrics/PerceivedComplexity

    # this is the single "short title" - the title without subtitle, part name, etc.
    # this may be useful for boosting and exact matching for search results
    # @return [Array<String>] the main title value(s) for Solr - can be array due to parallel titles
    def main_title(titles)
      cocina_title = primary_title(titles) || untyped_title(titles)
      cocina_title = other_title(titles) if cocina_title.blank?

      extract_main_title(cocina_title)
    end

    private

    attr_reader :strategy, :part_label

    def add_part_label(title)
      # when a digital serial
      title = title.sub(/[ .,]*$/, "").to_s
      add_punctuation? ? "#{title}, #{part_label}" : "#{title} #{part_label}"
    end

    def extract_title(cocina_title)
      return if cocina_title.blank?
      title_values = if cocina_title["value"]
        cocina_title["value"]
      elsif cocina_title["structuredValue"].present?
        rebuild_structured_value(cocina_title)
      elsif cocina_title["parallelValue"].present?
        extract_title_parallel_values(cocina_title)
      end
      result = [title_values].flatten.compact.map { |val| remove_trailing_punctuation(val.strip) }
      (result.length == 1) ? result.first : result
    end

    # strategy :first says to return a single value (default: true)
    # only_one_parallel_value? says to return a single value, even if that value is a parallelValue (default: false)
    #
    # rubocop:disable Metrics/PerceivedComplexity
    def extract_title_parallel_values(cocina_title)
      primary = cocina_title["parallelValue"].find { |pvalue| pvalue["status"] == "primary" }
      if primary && only_one_parallel_value? && strategy == :first
        # we have a primary title and we know we want a single value
        extract_title(primary)
      elsif only_one_parallel_value? && strategy == :first
        # no primary value;  algorithm says prefer an untyped value over a typed value for single value
        untyped = cocina_title["parallelValue"].find { |pvalue| pvalue["type"].blank? }
        extract_title(untyped || cocina_title["parallelValue"].first)
      else
        cocina_title["parallelValue"].map { |pvalue| extract_title(pvalue) }
      end
    end
    # rubocop:enable Metrics/PerceivedComplexity

    # @return [Array<String>] the main title value(s) for Solr - can be array due to parallel titles
    def extract_main_title(cocina_title) # rubocop:disable Metrics/PerceivedComplexity
      result = if cocina_title["value"]
        cocina_title["value"] # covers both title and main title types
      elsif cocina_title["structuredValue"].present?
        main_title_from_structured_values(cocina_title)
      elsif cocina_title["parallelValue"].present?
        primary = cocina_title["parallelValue"].find { |pvalue| pvalue["status"] == "primary" }
        if primary
          extract_main_title(primary)
        else
          cocina_title["parallelValue"].map { |pvalue| extract_main_title(pvalue) }
        end
      end
      return [] if result.blank?

      [result].flatten.compact.map { |val| remove_trailing_punctuation(val) }
    end

    def add_punctuation?
      @add_punctuation
    end

    def only_one_parallel_value?
      @only_one_parallel_value
    end

    def sortable?
      @sortable
    end

    # @return [Hash, nil] title that has status=primary
    def primary_title(cocina_titles)
      primary_title = cocina_titles.find { |title| title["status"] == "primary" }
      return primary_title if primary_title.present?

      # NOTE: structuredValues would only have status primary assigned as a sibling, not as an attribute

      cocina_titles.find do |title|
        title["parallelValue"]&.find do |parallel_title|
          parallel_title["status"] == "primary"
        end
      end
    end

    def untyped_title(titles)
      method = (strategy == :first) ? :find : :select
      untyped_title_for(titles.public_send(method))
    end

    # @return [Array[Hash]] first title that has no type attribute
    def untyped_title_for(titles)
      titles.each do |title|
        if title["parallelValue"].present?
          untyped_title_for(title["parallelValue"])
        else
          title["type"].nil? || title["type"] == "title"
        end
      end
    end

    # This is called when there is no primary title and no untyped title
    # @return [Hash, Array<Hash>] first title or all titles
    def other_title(titles)
      if strategy == :first
        titles.first
      else
        titles
      end
    end

    # @param cocina_title [Hash] title with structured values
    # @return [String] the title value from combining the pieces of the structured_values by type and order
    #   with desired punctuation per specs
    #
    # - nonsorting characters value is followed by a space, unless the nonsorting
    #   character count note has a numeric value equal to the length of the
    #   nonsorting characters value, in which case no space is inserted
    # - subtitle is preceded by space colon space, unless it is at the beginning
    #   of the title string
    # - partName and partNumber are always separated from each other by comma space
    # - first partName or partNumber in the string is preceded by period space
    # - partName or partNumber before nonsorting characters or main title is followed
    #   by period space
    #
    # for punctuation funky town, thank MARC and catalog cards
    #
    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/CyclomaticComplexity
    # rubocop:disable Metrics/MethodLength
    # rubocop:disable Metrics/PerceivedComplexity
    def rebuild_structured_value(cocina_title, sortable: false)
      result = ""
      part_name_number = ""
      cocina_title["structuredValue"].each do |structured_value| # rubocop:disable Metrics/BlockLength
        # There can be a structuredValue inside a structuredValue, for example,
        #   a uniform title where both the name and the title have internal StructuredValue
        return rebuild_structured_value(structured_value) if structured_value["structuredValue"].present?

        value = structured_value["value"]&.strip
        next unless value

        # additional types ignored here, e.g. name, uniform ...
        case structured_value["type"]&.downcase
        when "nonsorting characters"
          unless sortable?
            padding = non_sorting_padding(cocina_title, value)
            result = add_non_sorting_value(result, value, padding)
          end
        when "part name", "part number"
          # even if there is a partLabel, use any existing structuredValue
          # part name/number that remains for non-digital serials purposes
          if part_name_number.blank?
            part_name_number = part_name_number(cocina_title["structuredValue"])
            result = if !add_punctuation?
              [result, part_name_number].join(" ")
            elsif result.present?
              # part name/number is preceded by period space, unless it is at the beginning of the title string
              "#{result.sub(/[ .,]*$/, "")}. #{part_name_number}. "
            else
              "#{part_name_number}. "
            end
          end
        when "main title", "title"
          # nonsorting characters ending with hyphen, apostrophe or space should be slammed against the main title,
          #   even if we are not adding punctuation
          result = if add_punctuation? || result.ends_with?(" ") || result.ends_with?("-") || result.ends_with?("'")
            [result, value].join
          else
            [remove_trailing_punctuation(result), remove_trailing_punctuation(value)].select(&:presence).join(" ")
          end
        when "subtitle"
          result = if !add_punctuation?
            [result, value.sub(/^:/, "").strip].select(&:presence).join(" ")
          elsif result.present?
            # subtitle is preceded by space colon space, unless it is at the beginning of the title string
            "#{result.sub(/[. :]+$/, "")} : #{value.sub(/^:/, "").strip}"
          else
            result = value.sub(/^:/, "").strip
          end
        end
      end

      result
    end
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/CyclomaticComplexity
    # rubocop:enable Metrics/MethodLength
    # rubocop:enable Metrics/PerceivedComplexity

    # main_title is title.structuredValue.value with type 'main title' (or just title.value)
    # @param cocina_title [Hash] Title with structured values
    # @return [String] the main title value
    #
    # rubocop:disable Metrics/MethodLength
    # rubocop:disable Metrics/PerceivedComplexity
    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/CyclomaticComplexity
    def main_title_from_structured_values(cocina_title, sortable: false)
      result = ""
      # combine pieces of the cocina structuredValue into a single title
      cocina_title["structuredValue"].each do |structured_value|
        # There can be a structuredValue inside a structuredValue, for example,
        #   a uniform title where both the name and the title have internal StructuredValue
        return main_title_from_structured_values(structured_value) if structured_value["structuredValue"].present?

        value = structured_value["value"]&.strip
        next unless value

        case structured_value["type"]&.downcase
        when "nonsorting characters"
          unless sortable?
            padding = non_sorting_padding(cocina_title, value)
            result = add_non_sorting_value(result, value, padding)
          end
        when "main title", "title"
          result = if ["'", "-"].include?(result.last)
            [result, value].join
          else
            [remove_trailing_punctuation(result).strip, remove_trailing_punctuation(value).strip].select(&:presence).join(" ")
          end
        end
      end

      result
    end
    # rubocop:enable Metrics/MethodLength
    # rubocop:enable Metrics/PerceivedComplexity
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/CyclomaticComplexity

    # Thank MARC and catalog cards for this mess.
    def remove_trailing_punctuation(title)
      title.sub(%r{[ .,;:/\\]+$}, "")
    end

    def add_non_sorting_value(title_so_far, non_sorting_value, padding)
      non_sort_value = "#{non_sorting_value}#{padding}"
      if title_so_far.present?
        [title_so_far.strip, padding, non_sort_value].join
      else
        non_sort_value
      end
    end

    def non_sorting_padding(title, non_sorting_value)
      non_sort_note = title["note"]&.find { |note| note["type"]&.downcase == "nonsorting character count" }
      if non_sort_note
        padding_count = [non_sort_note["value"].to_i - non_sorting_value.length, 0].max
        " " * padding_count
      elsif ["'", "-"].include?(non_sorting_value.last)
        ""
      else
        " "
      end
    end

    # combine part name and part number:
    #   respect order of occurrence
    #   separated from each other by comma space
    def part_name_number(structured_values)
      title_from_part = ""
      structured_values.each do |structured_value|
        case structured_value["type"]&.downcase
        when "part name", "part number"
          value = structured_value["value"]&.strip
          next unless value

          title_from_part = append_part_to_title(title_from_part, value)

        end
      end
      title_from_part
    end

    def append_part_to_title(title_from_part, value)
      if !add_punctuation?
        [title_from_part, value].select(&:presence).join(" ")
      elsif title_from_part.strip.present?
        "#{title_from_part.sub(/[ .,]*$/, "")}, #{value}"
      else
        value
      end
    end
  end
end
