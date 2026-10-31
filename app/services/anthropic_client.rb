
require "net/http"
require "json"

# Minimal client for the Anthropic Messages API.
class AnthropicClient
  class Error < StandardError; end

  URL = URI("https://api.anthropic.com/v1/messages")
  API_VERSION = "2023-06-01"

  def initialize(api_key: ENV["ANTHROPIC_API_KEY"])
    @api_key = api_key
  end

  def messages(**params)
    raise Error, "ANTHROPIC_API_KEY is not set" if @api_key.blank?

    http = Net::HTTP.new(URL.host, URL.port)
    http.use_ssl = true
    http.open_timeout = 10
    http.read_timeout = 90

    request = Net::HTTP::Post.new(URL, "content-type" => "application/json",
                                       "x-api-key" => @api_key,
                                       "anthropic-version" => API_VERSION)
    request.body = params.to_json
    response = http.request(request)

    body = JSON.parse(response.body)
    unless response.is_a?(Net::HTTPSuccess)
      raise Error, "Anthropic API #{response.code}: #{body.dig("error", "message")}"
    end
    body
  rescue JSON::ParserError
    raise Error, "Anthropic API returned a non-JSON response"
  end
end