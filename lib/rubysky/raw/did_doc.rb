# frozen_string_literal: true

module RubySky
  module Raw
    # DID Document
    class DIDDoc
      attr_reader :did

      def initialize(did:, did_doc:)
        @did = did
        @did_doc = did_doc
      end
    end
  end
end
