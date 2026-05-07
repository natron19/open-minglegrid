class CharterParser
  class ParseError < StandardError
    attr_reader :refusal

    def initialize(message, refusal: false)
      super(message)
      @refusal = refusal
    end

    def refusal?
      @refusal
    end
  end

  def initialize(raw)
    @raw = raw.to_s
  end

  def parse!
    json = strip_fences(@raw)
    data = parse_json(json)
    check_refusal(data)
    validate_schema(data)
    data
  end

  private

  def strip_fences(text)
    text.strip.gsub(/\A```(?:json)?\n?/, "").gsub(/\n?```\z/, "").strip
  end

  def parse_json(text)
    JSON.parse(text)
  rescue JSON::ParserError => e
    raise ParseError, "Invalid JSON: #{e.message}"
  end

  def check_refusal(data)
    if data.key?("refusal")
      raise ParseError.new(data["refusal"], refusal: true)
    end
  end

  def validate_schema(data)
    validate_string_keys(data)
    validate_agreements(data)
    validate_sessions(data)
    validate_boundary_reminders(data)
  end

  def validate_string_keys(data)
    %w[purpose_statement meeting_structure member_commitments].each do |key|
      unless data[key].is_a?(String) && data[key].present?
        raise ParseError, "Missing or blank required key: #{key}"
      end
    end
  end

  def validate_agreements(data)
    agreements = data["agreements"]
    unless agreements.is_a?(Array) && agreements.size.between?(4, 5)
      raise ParseError, "agreements must be an Array with 4 or 5 entries (got #{agreements.inspect})"
    end
  end

  def validate_sessions(data)
    sessions = data["sessions"]
    unless sessions.is_a?(Array) && sessions.size == 4
      raise ParseError, "sessions must be an Array with exactly 4 entries (got #{sessions&.size})"
    end

    expected_numbers = [1, 2, 3, 4]
    actual_numbers   = sessions.map { |s| s["session_number"] }
    unless actual_numbers == expected_numbers
      raise ParseError, "sessions must have session_number values [1, 2, 3, 4] in order (got #{actual_numbers.inspect})"
    end
  end

  def validate_boundary_reminders(data)
    reminders = data["boundary_reminders"]
    unless reminders.is_a?(Array) && reminders.size == 2
      raise ParseError, "boundary_reminders must be an Array with exactly 2 entries (got #{reminders.inspect})"
    end
  end
end
