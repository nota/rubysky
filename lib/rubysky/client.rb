# frozen_string_literal: true

require "date"
require "json"
require "jwt"
require "net/http"

module RubySky
  # API Client
  class Client
    PDSHOST_BSKY_SOCIAL = "https://bsky.social"

    def self.from_refresh_jwt(refresh_jwt:, pds: PDSHOST_BSKY_SOCIAL)
      client = Raw::Client.from_refresh_jwt(refresh_jwt:, pds:)
      new(client:)
    end

    def self.from_app_password(identifier:, password:, pds: PDSHOST_BSKY_SOCIAL)
      client = Raw::Client.create_session(identifier:, password:, pds:)
      new(client:)
    end

    def initialize(client:)
      @client = client
    end

    def post(text:, images: [])
      unless images.empty?
        embed = Raw::ImageEmbed.new(images: images.map do |image|
          @client.upload_image(file: image[:data], mime_type: image[:mime_type], alt: image[:alt] || "")
        end)
      end
      Post.new(raw: @client.post(text: text, embed:), repo: @client.session.handle)
    end

    def refresh_jwt
      @client.session.refresh_jwt
    end
  end
end
