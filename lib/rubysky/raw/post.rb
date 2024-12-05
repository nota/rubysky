# frozen_string_literal: true

module RubySky
  module Raw
    class Post # :nodoc:
      def self.from_hash(hash)
        allocate.tap do |this|
          this.update_by_hash hash
        end
      end

      attr_reader :uri, :cid, :commit, :validation_status

      def initialize(uri:, cid:, commit:, validation_status:)
        @uri = uri
        @cid = cid
        @commit = commit
        @validation_status = validation_status
      end

      def update_by_hash(hash)
        @uri = hash["uri"]
        @cid = hash["cid"]
        @commit = hash["commit"]
        @validation_status = hash["validationStatus"]
      end
    end
  end
end
