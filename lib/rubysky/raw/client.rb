# frozen_string_literal: true

require "net/http"

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

      # app.bsky.embed.images lexicon
      UPLOAD_SIZE_LIMIT = 10_000_000

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

        facets = parse_facets(text:)

        record[:facets] = facets unless facets.empty?
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
        if body.size > UPLOAD_SIZE_LIMIT
          raise Error,
                "upload image size shoule be less than #{UPLOAD_SIZE_LIMIT} bytes(got #{body.size} bytes)"
        end

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
        jwt = JWT.decode(@session.access_jwt, nil, false, algorithm: "RS256")
        payload = jwt[0]
        payload["exp"] > Time.now.to_i + 10
      end

      def refresh_if_needed
        refresh! unless valid_access_jwt?
      end

      def refresh!(refresh_jwt: nil, pds: nil)
        @pds = pds if pds
        res = send_post(pds: @pds, path: REFRESH_SESSION_PATH, auth: refresh_jwt || @session.refresh_jwt)
        ensure_success(res:, called_from: REFRESH_SESSION_PATH)

        json = JSON.parse(res.body)
        @session = Session.from_hash(json)
      end

      def parse_facets(text:)
        facets = [] # : Array[facet]
        # parse_mentions もここでする必要が本当はあるよ。
        facets += parse_uris(text:)
        facets
      end

      def link_facet(start:, end:, uri:)
        {
          index: {
            byteStart: start,
            byteEnd: binding.local_variable_get(:end) # endは予約語
          },
          features: [
            {
              "$type": "app.bsky.richtext.facet#link",
              uri:
            }
          ]
        }
      end

      def parse_uris(text:)
        reg = URI::DEFAULT_PARSER.make_regexp(%w[http https])
        text.gsub(reg).map do
          m = Regexp.last_match
          link_facet(start: m.begin(0), end: m.end(0), uri: m.to_s)
        end
      end
    end
  end
end
