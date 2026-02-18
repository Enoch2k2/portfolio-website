module Pdf
  class ResumeTextFormatter
    MONTH_PATTERN = "(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)".freeze
    DATE_RANGE_PATTERN = /#{MONTH_PATTERN}\s+\d{4}\s*[-–]\s*(?:Present|#{MONTH_PATTERN}\s+\d{4})/i
    ROLE_WORDS = %w[
      Senior Lead Technical Software Engineering Instructor Coach Remote Hybrid Principal Staff
      Manager Developer Analyst Consultant
    ].freeze

    SECTION_HEADERS = [
      "Summary",
      "Experience",
      "Work Experience",
      "Education",
      "Projects",
      "Skills",
      "Certifications",
      "Awards",
      "Publications"
    ].freeze

    def initialize(raw_text:)
      @raw_text = raw_text.to_s
    end

    def call
      text = normalized_text
      return nil if text.blank?
      return normalize_markdown_text(text) if markdown_like?(text)

      lines = text.split("\n").map { |line| clean_line(line) }.reject(&:blank?)
      return text if lines.empty?

      result = []
      result << "# #{lines.shift}" if likely_name_line?(lines.first.to_s)

      current_header = nil
      current_block = []

      flush_block = lambda do
        next if current_block.empty?

        if current_header
          result << "## #{current_header}"
        end

        list_items, prose = current_block.partition { |line| bullet_like?(line) || list_candidate?(line) }
        list_items.each { |line| result << "- #{clean_list_line(line)}" }
        prose.each { |line| result << line }
        current_block.clear
      end

      lines.each do |line|
        detected_header = matched_header(line)
        if detected_header
          flush_block.call
          current_header = detected_header
        else
          current_block << line
        end
      end

      flush_block.call
      result.join("\n\n").squeeze("\n").strip.presence
    end

    private

    def normalized_text
      @raw_text
        .gsub("\r\n", "\n")
        .gsub(/\t+/, " ")
        .gsub(/[ ]{2,}/, " ")
        .gsub(/\n{3,}/, "\n\n")
        .strip
    end

    def markdown_like?(text)
      text.match?(/^\s*#{Regexp.escape('#')}/) || text.match?(/^\s*[-*]\s+/)
    end

    def normalize_markdown_text(text)
      text
        .split("\n")
        .flat_map { |line| split_dense_markdown_bullets(clean_line(line)) }
        .join("\n")
        .gsub(/\n{3,}/, "\n\n")
        .strip
    end

    def likely_name_line?(line)
      line.match?(/\A[a-zA-Z][a-zA-Z .'-]{2,}\z/) && line.split.size.between?(2, 4)
    end

    def matched_header(line)
      cleaned = line.gsub(/:+\z/, "").strip
      SECTION_HEADERS.find { |header| cleaned.casecmp?(header) }
    end

    def bullet_like?(line)
      line.match?(/\A[-*•]\s+/)
    end

    def list_candidate?(line)
      line.match?(/\A\d{4}\s*[-–]\s*\d{4}|\A\d{4}\s*[-–]\s*Present/i) ||
        line.match?(/\A[A-Za-z].{1,80}\|\s*.+/)
    end

    def clean_list_line(line)
      clean_line(line.sub(/\A[-*•]\s+/, "")).strip
    end

    def clean_line(line)
      line
        .to_s
        .then { |value| normalize_compound_artifacts(value) }
        .gsub(/,([^\s])/, ", \\1")
        .gsub(/;([^\s])/, "; \\1")
        .gsub(/:([^\s])/, ": \\1")
        .gsub(/\|([^\s])/, "| \\1")
        .gsub(/([^\s])\|/, "\\1 |")
        .gsub(/([a-z])([A-Z])/, "\\1 \\2")
        .gsub(/[ ]{2,}/, " ")
        .strip
    end

    def normalize_compound_artifacts(value)
      value
        .gsub(/Conductedlectures/i, "Conducted lectures")
        .gsub(/andcode-alongs/i, "and code-alongs")
        .gsub(/alongstoenhance/i, "alongs to enhance")
        .gsub(/enhancestudent/i, "enhance student")
        .gsub(/studentlearning/i, "student learning")
        .gsub(/learningand/i, "learning and")
        .gsub(/andcomprehension/i, "and comprehension")
        .gsub(/leadingto/i, "leading to")
        .gsub(/ledto/i, "led to")
        .gsub(/tohigher/i, "to higher")
        .gsub(/higherstudentengagement/i, "higher student engagement")
        .gsub(/successfulprojectcompletions/i, "successful project completions")
        .gsub(/codingandunderstanding/i, "coding and understanding")
        .gsub(/([A-Za-z]{4,}(?:ed|ing|ly|tion|ment|s))to([a-z]{3,})/i, "\\1 to \\2")
        .gsub(/([A-Za-z]{4,}(?:ed|ing|ly|tion|ment|s))and([a-z]{3,})/i, "\\1 and \\2")
    end

    def split_dense_markdown_bullets(line)
      return [line] unless line.start_with?("- ")

      content = line.sub(/\A-\s+/, "")
      return [line] if content.scan(DATE_RANGE_PATTERN).length < 2

      split_points = organization_split_points(content)
      return [line] if split_points.length < 2

      segments = []
      preface = content[0...split_points.first].to_s.strip
      segments << preface if preface.present?
      split_points.each_with_index do |start_idx, index|
        end_idx = split_points[index + 1] || content.length
        segment = content[start_idx...end_idx].to_s.strip
        segments << segment if segment.present?
      end

      segments.map { |segment| "- #{segment}" }
    end

    def organization_split_points(content)
      points = []
      content.to_enum(:scan, DATE_RANGE_PATTERN).each do
        date_start = Regexp.last_match.begin(0)
        points << organization_start_before_date(content, date_start)
      end
      points.compact.uniq.sort
    end

    def organization_start_before_date(content, date_start)
      window_start = [date_start - 90, 0].max
      window = content[window_start...date_start]
      org_match = window.match(/([A-Z][A-Za-z&.\-']+(?:\s+[A-Z][A-Za-z&.\-']+){1,2})\s+\z/)
      return nil unless org_match

      phrase = org_match[1]
      phrase_start = window_start + org_match.begin(1)
      words = phrase.split

      while words.length > 1 && ROLE_WORDS.include?(words.first)
        phrase_start += words.first.length + 1
        words.shift
      end

      phrase_start
    end
  end
end
