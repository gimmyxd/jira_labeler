# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'json'

class Jira
  def self.issue_type(id)
    uri = URI.parse("#{ENV['INPUT_JIRA_URL']}/rest/api/2/issue/#{id}")

    response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
      request = Net::HTTP::Get.new uri
      http.request request
    end

    if response.code == '200'
      response_body = JSON.parse(response.body)
      response_body.dig('fields', 'issuetype', 'name')
    else
      STDOUT.puts "call to #{ENV['INPUT_JIRA_URL']} failed"
      STDOUT.puts response.inspect
      nil
    end
  end
end
