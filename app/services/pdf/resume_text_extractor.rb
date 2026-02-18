require "pdf/reader"
require "stringio"

module Pdf
  class ResumeTextExtractor
    def initialize(file_blob:)
      @file_blob = file_blob
    end

    def call
      io = StringIO.new(@file_blob.download)
      reader = PDF::Reader.new(io)
      pages = reader.pages.map { |page| page.text.to_s.strip }.reject(&:blank?)
      text = pages.join("\n\n")
      text.presence
    rescue StandardError
      nil
    end
  end
end
