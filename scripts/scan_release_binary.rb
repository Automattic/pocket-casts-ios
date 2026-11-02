#!/usr/bin/env ruby
# frozen_string_literal: true

require 'digest'
require 'open3'
require_relative 'release_binary_archive'

# Scan a release binary.
module ReleaseBinaryScan
  URL = %r{\Ahttps?://}i
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
    neighbor_hits(items).uniq { |item| [item[:rule], item[:digest]] }
  end

  def scan_path(path)
    hits = []
    ReleaseBinaryArchive.each_binary(path) do |binary|
      hits.concat(scan_table(strings_of(binary)))
    end
    hits.uniq { |item| [item[:rule], item[:digest]] }
  end

  def strings_of(path)
    stdout, _stderr, status = Open3.capture3('/usr/bin/strings', '-a', '-n', '8', '-t', 'd', path.to_s)
    raise "strings failed for #{path}" unless status.success?

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

  def neighbor_hits(items)
    items.each_cons(2).filter_map do |(left_offset, left), (right_offset, right)|
      next unless adjacent?(left_offset, left, right_offset)

      if token_shaped?(left) && url?(right)
        hit('shaped-value-beside-url', left_offset, left)
      elsif token_shaped?(right) && url?(left)
        hit('shaped-value-beside-url', right_offset, right)
      end
    end
  end

  def url?(value)
    value.match?(URL)
  end

  def adjacent?(previous_offset, previous_text, offset)
    gap = offset - (previous_offset + previous_text.bytesize)
    gap.between?(1, 16)
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
