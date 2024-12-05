# frozen_string_literal: true

module RubySky
  # Post representation
  class Post
    def initialize(raw:, repo:)
      @raw = raw
      @repo = repo
    end

    def http_uri
      "https://bsky.app/profile/#{@repo}/post/#{@raw.uri.split("/")[-1]}"
    end
  end
end
