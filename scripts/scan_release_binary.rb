#!/usr/bin/env ruby
# frozen_string_literal: true

require 'digest'
require 'open3'
require 'tmpdir'

# Detect a Zendesk API token compiled into a release binary.
#
# Pocket Casts injects `ApiCredentials.zendeskAPIKey` at build time and emits
# it as the cstring immediately before `zendeskUrl`. Mach-O pads that pair to
# a 16-byte alignment, so the gap is wider than a single NUL.
module ReleaseBinaryScan
  HOST = %r{https?://[A-Za-z0-9.-]+\.zendesk\.com\b}i
  EMAIL_TOKEN = %r{/token:([A-Za-z0-9]{20,80})}
  SKIP_SUFFIXES = %w[.png .jpg .jpeg .gif .car .nib .storyboardc .metallib .mp3 .m4a .ttf .otf .pdf].freeze
  MIN_BINARY_BYTES = 64 * 1024

  module_function

  def token_shaped?(value, min_len: 20)
    return false unless value.match?(/\A[A-Za-z0-9]{#{min_len},80}\z/)
    return false if value.match?(/\A[0-9a-fA-F]+\z/)
    return false unless value.match?(/\d/) && value.match?(/[A-Za-z]/)

    shannon(value) >= 3.0
  end

  def scan_table(items)
    hits = email_token_hits(items)
    hits.concat(neighbor_hits(items))
    hits.uniq { |item| [item[:rule], item[:digest]] }
  end

  def scan_path(path)
    hits = []
    each_binary(path) { |binary| hits.concat(scan_table(strings_of(binary))) }
    hits.uniq { |item| [item[:rule], item[:digest]] }
  end

  def strings_of(path)
    stdout, status = Open3.capture2('/usr/bin/strings', '-a', '-n', '8', '-t', 'd', path.to_s)
    return [] unless status.success?

    stdout.each_line.filter_map { |line| parse_strings_line(line) }
  end

  def binary?(path)
    return false unless File.file?(path)
    return false if debug_symbols?(path)
    return false if SKIP_SUFFIXES.include?(File.extname(path).downcase)

    File.size(path) >= MIN_BINARY_BYTES
  end

  def debug_symbols?(path)
    path.split(File::SEPARATOR).any? { |part| part == 'dSYMs' || part.end_with?('.dSYM') }
  end

  def email_token_hits(items)
    items.filter_map do |offset, text|
      match = text.match(EMAIL_TOKEN)
      next unless match && token_shaped?(match[1])

      hit('zendesk-email-token', offset, match[1])
    end
  end

  def neighbor_hits(items)
    items.each_cons(2).filter_map do |(left_offset, left), (right_offset, right)|
      next unless adjacent?(left_offset, left, right_offset)
      next unless right.match?(HOST)
      next unless token_shaped?(left)

      hit('zendesk-token-before-host', left_offset, left)
    end
  end

  def adjacent?(previous_offset, previous_text, offset)
    gap = offset - (previous_offset + previous_text.bytesize)
    gap >= 1 && gap <= 16
  end

  def hit(rule, offset, value)
    {
      rule: rule,
      offset: offset,
      redacted: redact(value),
      digest: Digest::SHA256.hexdigest(value)[0, 16]
    }
  end

  def redact(value)
    return '•' * value.length if value.length <= 8

    "#{value[0, 4]}…#{value[-2, 2]}"
  end

  def parse_strings_line(line)
    offset, text = line.strip.split(' ', 2)
    return if text.nil? || text.empty? || !offset.match?(/\A\d+\z/)

    [offset.to_i, text]
  end

  def shannon(value)
    length = value.length.to_f
    value.chars.tally.sum do |_char, count|
      freq = count / length
      -freq * Math.log2(freq)
    end
  end

  def each_binary(path)
    return yield path unless archive?(path)

    Dir.mktmpdir('release-binary-scan') do |dir|
      extract(path, dir)
      binaries_under(dir).each { |binary| yield binary }
    end
  end

  def archive?(path)
    path.end_with?('.ipa', '.zip')
  end

  def binaries_under(root)
    Dir.glob(File.join(root, '**', '*')).select { |candidate| binary?(candidate) }
  end

  def extract(archive, dest)
    list_archive(archive).each { |relative| refuse_slip(dest, relative) }
    _stdout, status = Open3.capture2('/usr/bin/unzip', '-q', archive, '-d', dest)
    raise "unzip failed for #{archive}" unless status.success?
  end

  def list_archive(archive)
    stdout, status = Open3.capture2('/usr/bin/unzip', '-Z1', archive)
    raise "unzip failed to list #{archive}" unless status.success?

    stdout.each_line.map(&:strip).reject(&:empty?)
  end

  def refuse_slip(dest, relative)
    root = File.expand_path(dest)
    target = File.expand_path(relative, root)
    return if target == root || target.start_with?("#{root}#{File::SEPARATOR}")

    raise "refusing to extract #{relative}"
  end
end

if $PROGRAM_NAME == __FILE__
  target = ARGV.fetch(0) { abort "usage: #{$PROGRAM_NAME} <ipa-or-archive>" }
  abort "no such file: #{target}" unless File.file?(target)

  hits = ReleaseBinaryScan.scan_path(target)
  puts "scanned #{target}"
  hits.each do |item|
    puts "critical #{item[:rule]} offset=#{item[:offset]} #{item[:redacted]} digest=#{item[:digest]}"
  end
  exit(hits.empty? ? 0 : 1)
end
