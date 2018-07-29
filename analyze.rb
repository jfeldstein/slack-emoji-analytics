require 'slack-ruby-client'

Slack.configure do |config|
  config.token = ENV['SLACK_TOKEN']
  raise 'Missing ENV[SLACK_TOKEN]!' unless config.token
end


client = Slack::Web::Client.new

client.auth_test

users = client.users_list.members

puts "Seeing #{users.length} users"

reaction_totals = {}
user_favorites = []
skin_tones = [0, 0, 0, 0, 0, 0]

users.each do |user|
  history = client.reactions_list(
    user: user.id,
    full: true,
    count: 1000
  )

  puts user.name
  user_totals = {}

  items = history.items.map{|item| [item.message, item.comment, item.file].compact }.flatten
  seen = []

  items.each do |item|
    id = item.ts || item.id || item.created
    next if seen.include? id
    seen << id

    reactions = item.reactions

    puts reactions.map(&:name).join(', ')

    reactions.map(&:name).each do |reaction|
      reaction, skin_tone_str = reaction.split('::')

      if skin_tone_str
        puts skin_tone_str[-1].inspect
        skin_tones[1+skin_tone_str[-1].to_i] += 1
      end

      reaction_totals[reaction] ||= {}
      reaction_totals[reaction][user.name] ||= 0
      reaction_totals[reaction][user.name] += 1

      user_totals[reaction] ||= 0
      user_totals[reaction] += 1
    end
  end

  user_favorites << [user.name, user_totals.sort.first].flatten

  puts
end

#puts "Reaction Totals", reaction_totals.inspect
popular = []
reaction_totals.each do |emoji, counts|
  popular << {
    name: emoji,
    total: counts.values.inject(0, :+),
  }
end
popular.sort_by! { |react| react[:total] }

user_favorites.sort_by! { |user_fav| user_fav[0] }

puts
puts

puts "*User Favorites*", user_favorites.map{|f| f[2].nil? ? nil : "@#{f[0]}: :#{f[1]}: (Used x#{f[2]})"}.compact
puts
puts "*10 most popular reactions*", popular.last(10).reverse.map{|r| ":#{r[:name]}: (Used x#{r[:total]})"}
puts
puts "*Skin Tone Popularity*", skin_tones.map.with_index{|t, s| ":wave::skin-tone-#{s+1}: x#{t}" }
