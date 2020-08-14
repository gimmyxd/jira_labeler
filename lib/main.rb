# frozen_string_literal: true

require 'json'
require 'octokit'
require 'yaml'
require_relative 'helpers/jira'

class Application
  class << self
    def run
      event = JSON.parse(File.read(ENV['GITHUB_EVENT_PATH']))
      pull_request = event['pull_request']
      pr_labels = pull_request['labels']

      if pr_labels.any?
        STDOUT.puts "Already has #{pr_labels}, nothing to do"
      else
        title = client.issue(ENV['GITHUB_REPOSITORY'], pull_request['number']).title
        issue_uid = title[/\((.*?)\)/, 1]
        puts "title: #{title}"
        puts "issue_uid: #{issue_uid}"
        issue_type = nil
        issue_type = Jira.issue_type(issue_uid) if issue_uid =~ /[A-z]+-\d+/

        puts "issue_type: #{issue_type}"

        label = if issue_type
                  label_by_issue_type(issue_type)
                else
                  label_by_keyword(issue_uid)
                end
        puts "label: #{label}"
        update_label(label) if label
      end
    end

    private

    def event
      @event ||= JSON.parse(File.read(ENV['GITHUB_EVENT_PATH']))
    end

    def pull_request
      @pull_request ||= event['pull_request']
    end

    def client
      @client ||= Octokit::Client.new(access_token: ENV['INPUT_REPO_TOKEN'])
    end

    def update_label(label)
      client.add_labels_to_an_issue(ENV['GITHUB_REPOSITORY'], pull_request['number'], [label])
    end

    def rules
      @rules ||= YAML.load_file(ENV['INPUT_CONFIG_PATH'])
    rescue Errno::ENOEN
      STDOUT.puts 'rules config_path not set'
      exit 0
    end

    def label_by_keyword(keyword)
      keyword_rules = find_rules('keywords')
      (keyword_rules.find do |_, value|
        value['keywords'].include?(keyword)
      end || []).first
    end

    def label_by_issue_type(issue_type)
      issue_type_rules = find_rules('issue_type')
      (issue_type_rules.find do |_, value|
        value['issue_type'].include?(issue_type)
      end || []).first
    end

    def find_rules(key_value)
      (rules.select do |_, value|
        next unless value.is_a? Hash

        value.keys.first == key_value
      end || {})
    end
  end
end

Application.run
