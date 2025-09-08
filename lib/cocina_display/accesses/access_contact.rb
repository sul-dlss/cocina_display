module CocinaDisplay
  module Accesses
    class AccessContact < Access
      # Whether the access contact info is a contact email.
      # @return [Boolean]
      def contact_email?
        type == "email"
      end
    end
  end
end
