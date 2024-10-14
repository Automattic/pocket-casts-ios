#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'
require 'open3'

STRINGS_FILE = File.join('podcasts', 'en.lproj', 'Localizable.strings')
KNOWN_WORDS = %w[
  Pocketcasts Automattic
  OPML opml URL url RSS rss
  Preselect preselect
  Unplayed unplayed
  Autoplay autoplay
  Unarchive unarchive Unarchived unarchived Unarchiving unarchiving
  Unstar unstar Unstarring unstarring
  EP
  Alexa Siri Sonos Castbox castbox
  uuid VPN macOS
  outro Rosé
  Bazinga Wahhh Aaaah Heyooo Ew
].freeze

YELLOW_BOLD = "\e[33;1m"
RED = "\e[31;1m"
RESET = "\e[0m"

def parse_strings_as_dict
  out, err, status = Open3.capture3('plutil', '-convert', 'json', '-o', '-', STRINGS_FILE)
  unless status.success?
    puts "Encountered an error while trying to convert #{STRINGS_FILE} to JSON: #{err}"
    exit 1
  end
  JSON.parse(out)
end

# Spell-checks the `text` for typos
# @param key [String] The key in the strings file this text comes from
# @param text [String] The string to check for typos
# @return [Integer] The number of typos found
#
def spellcheck(key:, text:)
  out, err, status = Open3.capture3('aspell', 'list', '--lang=en-us', stdin_data: text)
  raise " ! Error spellchecking key `#{key}`: #{err}" unless err.empty? && status.success?

  typos = out.split("\n") - KNOWN_WORDS
  return 0 if typos.empty?

  highlighted = typos.reduce(text) { |str, typo| str.gsub(typo, "#{RED}#{typo}#{RESET}") }
  puts "#{YELLOW_BOLD}Key#{RESET}: #{key}"
  puts "#{YELLOW_BOLD}Text#{RESET}: #{highlighted}"
  puts '------'
  typos.count
end

##############################
# Main
##############################
_, status = Open3.capture2e('which', 'aspell')
raise 'Please install the `aspell` utility using `brew install aspell` first' unless status.success?

dict = parse_strings_as_dict
typos_count = 0
dict.each do |key, str|
  typos_count += spellcheck(key: key, text: str)
end

puts "#{typos_count} typo(s) found"
exit 1 unless typos_count.zero?
