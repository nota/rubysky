# frozen_string_literal: true

module RubySky
  module Raw
    class ImageEmbed # :nodoc:
      def initialize(images:)
        @images = images
      end

      def as_json(*_args)
        {
          "$type": "app.bsky.embed.images",
          images: @images
        }
      end

      def to_json(*_args)
        as_json.to_json
      end
    end
  end
end
