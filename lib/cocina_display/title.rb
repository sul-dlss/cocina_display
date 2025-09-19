module CocinaDisplay
  # A group of related {TitleValue}s associated with an item.
  class Title
    # The underlying Cocina hash.
    attr_reader :cocina

    # Type of the title, e.g. "uniform", "alternative", etc.
    # @see https://github.com/sul-dlss/cocina-models/blob/main/docs/description_types.md#title-types
    # @return [String, nil]
    attr_accessor :type

    # Status of the title, e.g. "primary".
    # @return [String, nil]
    attr_accessor :status

    # Create a new Title object.
    # @param cocina [Hash]
    # @param part_label [String, nil] part label for digital serials
    # @param part_numbers [Array<String>] part numbers for related resources
    def initialize(cocina, part_label: nil, part_numbers: nil)
      @cocina = cocina
      @part_label = part_label
      @part_numbers = part_numbers
      @type = cocina["type"].presence
      @status = cocina["status"].presence
    end

    # Label used when displaying the title.
    # @return [String]
    def label
      cocina["displayLabel"].presence || type_label
    end

    # Does this title have a type?
    # @return [Boolean]
    def type?
      type.present?
    end

    # Is this marked as a primary title?
    # @return [Boolean]
    def primary?
      status == "primary"
    end

    # The string representation of the title, for display.
    # @see #display_title
    # @return [String, nil]
    def to_s
      display_title
    end

    # The short form of the title, without subtitle, part name, etc.
    # @note This corresponds to the "short title" in MODS XML, or MARC 245$a only.
    # @return [String, nil]
    # @example "M. de Courville"
    def short_title
      short_title_str.presence || cocina["value"]
    end

    # The long form of the title, including subtitle, part name, etc.
    # @note This corresponds to the entire MARC 245 field.
    # @return [String, nil]
    # @example "M. de Courville [estampe]"
    def full_title
      full_title_str.presence || cocina["value"]
    end

    # The long form of the title, with added punctuation between parts if not present.
    # @note This corresponds to the entire MARC 245 field.
    # @return [String, nil]
    # @example "M. de Courville : [estampe]"
    def display_title
      display_title_str.presence || cocina["value"]
    end

    # A string value for sorting by title.
    # Ignores punctuation, leading/trailing spaces, and non-sorting characters.
    # If no title is present, returns a high Unicode value so it sorts last.
    # @return [String]
    def sort_title
      return "\u{10FFFF}" unless full_title

      full_title[nonsorting_char_count..]
        .unicode_normalize(:nfd) # Prevent accents being stripped
        .gsub(/[[:punct:]]*/, "")
        .gsub(/\W{2,}/, " ")  # Collapse whitespace after removing punctuation
        .strip
    end

    private

    # Generate the short title by joining main title and nonsorting characters with spaces.
    # @return [String, nil]
    def short_title_str
      Utils.compact_and_join([nonsorting_chars_str, main_title_str])
    end

    # Generate the full title by joining all title components with spaces.
    # @return [String, nil]
    def full_title_str
      Utils.compact_and_join([nonsorting_chars_str, main_title_str, subtitle_str, parts_str])
    end

    # Generate the display title by joining all components with punctuation:
    # - Join main title and subtitle with " : "
    # - Join part name/number/label with ", "
    # - Join part string with preceding title with ". "
    # - Prepend nonsorting characters with specified padding
    # - Prepend associated names with ". "
    # @return [String, nil]
    def display_title_str
      title_str = Utils.compact_and_join([main_title_str, subtitle_str], delimiter: " : ")
      title_str = Utils.compact_and_join([title_str, parts_str(delimiter: ", ")], delimiter: ". ")
      title_str = Utils.compact_and_join([nonsorting_chars_str, title_str]) if nonsorting_chars_str.present?
      title_str = Utils.compact_and_join([names_str, title_str], delimiter: ". ") if names_str.present?
      title_str.presence
    end

    # All nonsorting characters joined together with padding applied.
    # @return [String, nil]
    def nonsorting_chars_str
      Utils.compact_and_join(Array(title_components["nonsorting characters"])).ljust(nonsorting_char_count, " ")
    end

    # The main title component(s), joined together.
    # @return [String, nil]
    def main_title_str
      Utils.compact_and_join(Array(title_components["main title"]))
    end

    # The subtitle components, joined together.
    # @return [String, nil]
    def subtitle_str
      Utils.compact_and_join(Array(title_components["subtitle"]))
    end

    # The part name, number, and label components, joined together.
    # Default delimiter is a space, but can be overridden.
    # @return [String, nil]
    def parts_str(delimiter: " ")
      Utils.compact_and_join(
        Array(title_components["part number"] || @part_numbers) +
        Array(title_components["part name"]) +
        [@part_label],
        delimiter: delimiter
      )
    end

    # The associated names, joined together with periods.
    # @note Only present for uniform titles.
    # @return [String, nil]
    def names_str
      Utils.compact_and_join(names, delimiter: ". ")
    end

    # Destructured title components, organized by type.
    # Unstructured titles and components with no type are grouped under "main title".
    # @return [Hash<String, Array<String>>]
    # @see https://github.com/sul-dlss/cocina-models/blob/main/docs/description_types.md#title-part-types-for-structured-value
    def title_components
      Utils.flatten_nested_values(cocina).each_with_object({}) do |node, hash|
        type = case node["type"]
        when "uniform", "alternative", "abbreviated", "translated", "transliterated", "parallel", "supplied", nil
          "main title"
        else
          node["type"]
        end
        hash[type] ||= []
        hash[type] << node["value"]
      end.compact_blank
    end

    # Uniform titles can have associated person names.
    # @return [String, nil]
    def names
      Janeway.enum_for("$.note[?(@.type=='associated name')]", cocina).map do |name|
        Contributors::Name.new(name).to_s(with_date: true)
      end
    end

    # Number of nonsorting characters to ignore at the start of the title.
    # @return [Integer, nil]
    def nonsorting_char_count
      Janeway.enum_for("$.note[?(@.type=='nonsorting character count')].value", cocina).first&.to_i || 0
    end

    # Type-specific label for the title, falling back to a generic "Title".
    # @return [String]
    def type_label
      I18n.t(type&.parameterize&.underscore, scope: "cocina_display.field_label.title", default: :title)
    end
  end
end
