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
  if user.deleted
    puts "Skipping #{user.name} (deleted)"
    next
  end

  puts "Fetching #{user.name}"

  history = client.reactions_list(
    user: user.id,
    full: true,
    count: 1000,
    oldest: 28.days.ago
  )

  user_totals = {}

  items = history.items.map{|item| [item.message, item.comment, item.file].compact }.flatten
  seen = []

  items.each do |item|
    id = item.ts || item.id || item.created
    next if seen.include? id
    seen << id

    reactions = item.reactions

    #puts reactions.map(&:name).join(', ')

    reactions.map(&:name).each do |reaction|
      reaction, skin_tone_str = reaction.split('::')

      if skin_tone_str
        skin_tones[(skin_tone_str.last.to_i)-1] += 1
      end

      reaction_totals[reaction] ||= {}
      reaction_totals[reaction][user.name] ||= 0
      reaction_totals[reaction][user.name] += 1

      user_totals[reaction] ||= 0
      user_totals[reaction] += 1
    end
  end

  user_total = user_totals.values.inject(0, :+)
  user_unique = user_totals.keys.length
  user_favorites << [user.name, user_unique, user_total, user_totals.sort_by{ |_e, c| c }.last(3).reverse].flatten

  puts
end

#puts "Reaction Totals", reaction_totals.inspect
popular = []
reaction_totals.each do |emoji, counts|
  popular << {
    name: emoji,
    total: counts.values.inject(0, :+),
    people: counts.keys.length,
  }
end
popular.sort_by! { |react| react[:total] }

user_favorites.sort_by! { |user_fav| user_fav[0] }

puts
puts

puts "*User Favorites*", user_favorites.map{|f| f[2].nil? ? nil : "@#{f[0]} reacted #{f[2]} times using #{f[1]} emojis (Favs: :#{f[3]}:x#{f[4]}, :#{f[5]}:x#{f[6]}, :#{f[7]}:x#{f[8]}"}.compact
puts
puts "*10 most popular reactions*", popular.last(10).reverse.map{|r| ":#{r[:name]}: (Used x#{r[:total]} by #{r[:people]} people)"}
puts
puts "*Skin Tone Popularity*", skin_tones.map.with_index{|t, s| ":wave::skin-tone-#{s+1}: x#{t}" }
