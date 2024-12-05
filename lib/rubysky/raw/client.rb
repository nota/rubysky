# frozen_string_literal: true

module RubySky
  module Raw # :nodoc:
    class Client # :nodoc:
      module SendRequester # :nodoc:
        private

        def send_post(pds:, path:, body: nil, headers: {
          "Content-Type" => "application/json",
          "Accept" => "application/json"
        }, auth: nil)
          uri = URI.parse(pds + path)
          raise Error, "Invalid URI" if uri.host.nil?

          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = true if uri.scheme == "https"

          req = Net::HTTP::Post.new(path)
          req.body = body if body
          headers.merge!({ "Authorization" => "Bearer #{auth}" }) if auth
          headers.each do |k, v|
            req[k] = v
          end

          http.request(req)
        end

        def ensure_success(res:, expected_code: "200", called_from: nil)
          raise Error, "#{called_from || "Request"} failed #{res} #{res.body}" unless res.code == expected_code
        end
      end

      include SendRequester
      extend SendRequester

      CREATE_SESSION_PATH = "/xrpc/com.atproto.server.createSession"
      GET_SESSION_PATH = "/xrpc/com.atproto.server.getSession"
      REFRESH_SESSION_PATH = "/xrpc/com.atproto.server.refreshSession"
      CREATE_RECORD_PATH = "/xrpc/com.atproto.repo.createRecord"
      UPLOAD_BLOB_PATH = "/xrpc/com.atproto.repo.uploadBlob"

      POST_COLLECTION = "app.bsky.feed.post"

      attr_reader :pds, :session

      def self.create_session(identifier:, password:, pds:)
        res = send_post(pds:, path: CREATE_SESSION_PATH,
                        body: { identifier: identifier, password: password }.to_json)
        ensure_success(res:, called_from: CREATE_SESSION_PATH)

        json = JSON.parse(res.body)
        new(
          pds:,
          session: Session.from_hash(json)
        )
      end

      def self.from_refresh_jwt(refresh_jwt:, pds:)
        allocate.tap do |this|
          this.send :refresh!, refresh_jwt:, pds:
        end
      end

      def initialize(pds:, session:)
        @pds = pds
        @session = session
      end

      def post(text:, embed: nil, created_at: DateTime.now.iso8601)
        # refresh if needed
        record = {
          text: text,
          createdAt: created_at
        } # : Hash[Symbol, untyped]

        record[:embed] = embed if embed

        res = send_post(pds: @pds, path: CREATE_RECORD_PATH,
                        body: {
                          repo: @session.handle,
                          collection: POST_COLLECTION,
                          record:
                        }.to_json,
                        auth: @session.access_jwt)
        ensure_success(res:, called_from: CREATE_RECORD_PATH)

        Post.from_hash(JSON.parse(res.body))
      end

      def upload_blob(file:, mime_type:)
        body = file.read
        res = send_post(pds: @pds, path: UPLOAD_BLOB_PATH,
                        body:,
                        headers: {
                          "Content-Type" => mime_type,
                          "Accept" => "application/json"
                        },
                        auth: @session.access_jwt)
        ensure_success(res:, called_from: UPLOAD_BLOB_PATH)

        JSON.parse(res.body)["blob"]
      end

      def upload_image(file:, mime_type:, alt: "")
        blob = upload_blob(file:, mime_type:)
        { "image" => blob, "alt" => alt }
      end

      private

      def valid_access_jwt?
        jwt = JWT.decode(@access_jwt, nil, false, algorithm: "RS256")
        payload = jwt[0]
        payload["exp"] > Time.now.to_i + 10
      end

      def refresh_if_needed
        refresh! unless valid_access_jwt?
      end

      def refresh!(refresh_jwt: nil, pds: nil)
        @refresh_jwt = refresh_jwt if refresh_jwt
        @pds = pds if pds
        res = send_post(pds: @pds, path: REFRESH_SESSION_PATH, auth: @refresh_jwt)
        ensure_success(res:, called_from: REFRESH_SESSION_PATH)

        json = JSON.parse(res.body)
        @session = Session.from_hash(json)
      end
    end
  end
end
