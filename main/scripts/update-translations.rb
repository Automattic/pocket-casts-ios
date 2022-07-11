#!/usr/bin/env ruby
# frozen_string_literal: true

require 'fileutils'

ALL_LANGS = {
  'de' => 'de',         # German
  'es' => 'es',         # Spanish
  'es-mx' => 'es-MX',   # Spanish (Mexico)
  'fr' => 'fr',         # French
  'fr-ca' => 'fr-CA',   # French (Canada)
  'it' => 'it',         # Italian
  'ja' => 'ja',         # Japanese
  'nl' => 'nl',         # Dutch
  'pt-br' => 'pt-BR',   # Portuguese (Brazil)
  'ru' => 'ru',         # Russian
  'sv' => 'sv',         # Swedish
  'zh-cn' => 'zh-Hans', # Chinese (China)
  'zh-tw' => 'zh-Hant' # Chinese (Taiwan)
}.freeze

langs = {}
strings_filter = ''
strings_file_ext = ''
download_url = 'https://translate.wordpress.com/projects/pocket-casts/ios/'
if ARGV.count.positive?
  if ARGV[0] == 'review'
    langs = ALL_LANGS

    strings_filter = "filters[status]=#{ARGV[1]}\&"
    strings_file_ext = "_#{ARGV[1]}"
    download_url = 'https://translate.wordpress.com/projects/pocket-casts/ios/'
  else
    ARGV.each do |key|
      unless (local = ALL_LANGS[key])
        puts "Unknown language #{key}"
        exit 1
      end
      langs[key] = local
    end
  end
else
  langs = ALL_LANGS
end

script_root = __dir__
project_dir = File.dirname(script_root)

langs.each do |code, local|
  lang_dir = File.join(project_dir, 'podcasts', "#{local}.lproj")
  puts "Updating #{code} in #{lang_dir}"
  system 'mkdir', '-p', lang_dir

  destination = "#{lang_dir}/Localizable#{strings_file_ext}.strings"
  backup_destination = "#{destination}.bak"

  # Step 2 – Download the new strings
  FileUtils.copy destination, backup_destination if File.exist? destination

  url = "#{download_url}/#{code}/default/export-translations?#{strings_filter}format=strings"

  system('curl', '-fgsLo', destination, url) or raise "Error downloading #{url}"

  # Step 3 – Validate the new file
  if !File.exist?(destination) || File.size(destination).to_f.zero?
    puts "\e[31mFatal Error: #{destination} appears to be empty. Exiting.\e[0m"
    abort
  end

  # References a file like: "#{lang_dir}.Localizable-old.strings" where strings_file_ext == "old"
  strings_file_path = File.join(lang_dir, "Localizable#{strings_file_ext}.strings")

  system 'plutil', '-lint', strings_file_path

  # Clean up after ourselves
  FileUtils.rm_f backup_destination
end

extract_siri_translations_script_path = File.join(script_root, 'extract-siri-translations.swift')
system extract_siri_translations_script_path if strings_filter.empty?
