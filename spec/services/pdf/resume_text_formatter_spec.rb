require 'rails_helper'

module Pdf
  RSpec.describe ResumeTextFormatter do
    it 'formats plain extracted resume text into readable markdown sections' do
      raw_text = <<~TEXT
        Jane Developer
        jane@example.com | github.com/jane

        Experience
        Senior Engineer | Acme Corp
        2021 - Present
        Led platform migrations

        Skills
        Ruby
        React
      TEXT

      formatted = described_class.new(raw_text: raw_text).call

      expect(formatted).to include('# Jane Developer')
      expect(formatted).to include('## Experience')
      expect(formatted).to include('- Senior Engineer | Acme Corp')
      expect(formatted).to include('## Skills')
      expect(formatted).to include('Ruby')
    end

    it 'returns markdown unchanged when already structured' do
      markdown = "# Name\n\n## Experience\n\n- Built systems"
      expect(described_class.new(raw_text: markdown).call).to eq(markdown)
    end

    it 'cleans punctuation spacing and jammed words in markdown-like text' do
      markdown = "# Enoch Griffith\n- Ironton,MO|(573)872-0432|email@example.com\n- Conductedlectures,workshops,andcode-alongstoenhancestudentlearningandcomprehension,leadingtohigherstudentengagement"
      formatted = described_class.new(raw_text: markdown).call

      expect(formatted).to include("Ironton, MO | (573)872-0432 | email@example.com")
      expect(formatted).to include("Conducted lectures, workshops, and code-alongs to enhance student learning and comprehension, leading to higher student engagement")
    end

    it 'splits dense markdown bullets when multiple organization date ranges are merged' do
      markdown = <<~MD
        ## Experience
        - Facilitated study groups and coding sessions Flatiron School Jul 2018 - Present Senior Instructor Remote Flatiron School Dec 2017 - Jul 2018 Technical Coach Lead Remote Flatiron School Jun 2016 - Dec 2017 Technical Coach Remote
      MD

      formatted = described_class.new(raw_text: markdown).call

      expect(formatted).to include("- Facilitated study groups and coding sessions")
      expect(formatted).to include("- Flatiron School Jul 2018 - Present Senior Instructor Remote")
      expect(formatted).to include("- Flatiron School Dec 2017 - Jul 2018 Technical Coach Lead Remote")
      expect(formatted).to include("- Flatiron School Jun 2016 - Dec 2017 Technical Coach Remote")
    end
  end
end
