# frozen_string_literal: true

module RubySky
  module Raw # :nodoc:
    class Session # :nodoc:
      attr_reader :refresh_jwt, :access_jwt, :did_doc, :handle, :email,
                  :email_confirmed, :email_auth_factor, :active, :status

      def initialize(refresh_jwt:, access_jwt:, did_doc:, handle:, email:,
                     email_confirmed:, email_auth_factor:, active:, status:)
        @refresh_jwt = refresh_jwt
        @access_jwt = access_jwt
        @did_doc = did_doc
        @handle = handle
        @email = email
        @email_confirmed = email_confirmed
        @email_auth_factor = email_auth_factor
        @active = active
        @status = status
      end

      def self.from_hash(hash)
        allocate.tap do |this|
          this.update_by_hash hash
        end
      end

      def update_by_hash(hash)
        @refresh_jwt = hash["refreshJwt"]
        @access_jwt = hash["accessJwt"]
        @did_doc = DIDDoc.new(did: hash["did"], did_doc: hash["didDoc"])
        @handle = hash["handle"]
        @email = hash["email"]
        @email_confirmed = hash["emailConfirmed"]
        @email_auth_factor = hash["emailAuthFactor"]
        @active = hash["active"]
        @status = hash["status"]
      end
    end
  end
end
