# frozen_string_literal: true

require_relative "rubysky/raw/client"
require_relative "rubysky/raw/did_doc"
require_relative "rubysky/raw/embed"
require_relative "rubysky/raw/post"
require_relative "rubysky/raw/session"

require_relative "rubysky/client"
require_relative "rubysky/post"
require_relative "rubysky/version"

module RubySky
  # basic class for error handling
  class Error < StandardError; end
  # Your code goes here...
end
