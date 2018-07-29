require 'slack-ruby-client'

client = Slack::Web::Client.new token: ENV['SLACK_TOKEN']

puts client.auth_test
