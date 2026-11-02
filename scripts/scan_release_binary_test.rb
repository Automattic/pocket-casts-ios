# frozen_string_literal: true

require 'minitest/autorun'
require 'open3'
require 'tmpdir'
require_relative 'scan_release_binary'

TOKEN = 'ZdTestTokenNotReal0123456789abcdEF'
HOST = 'https://acme.zendesk.com'

# Unit tests for the release-binary Zendesk token scan.
class ReleaseBinaryScanTest < Minitest::Test
  def test_rejects_identifiers_and_hex
    refute ReleaseBinaryScan.token_shaped?('loggingEncryptionKey')
    refute ReleaseBinaryScan.token_shaped?('0123456789abcdef0123456789abcdef')
    assert ReleaseBinaryScan.token_shaped?(TOKEN)
  end

  def test_alignment_gap_counts_as_packed
    packed = [[100, TOKEN], [100 + TOKEN.bytesize + 8, HOST]]
    hits = ReleaseBinaryScan.scan_table(packed)
    rules = hits.map { |hit| hit[:rule] }
    assert_equal ['zendesk-token-before-host'], rules
    refute_includes hits.first[:redacted], TOKEN

    far = [[100, TOKEN], [100 + TOKEN.bytesize + 17, HOST]]
    assert_empty ReleaseBinaryScan.scan_table(far)
  end

  def test_email_token_literal
    hits = ReleaseBinaryScan.scan_table([[0, "user@example.com/token:#{TOKEN}"]])
    rules = hits.map { |hit| hit[:rule] }
    assert_equal ['zendesk-email-token'], rules
  end

  def test_skips_debug_symbol_bundles
    assert ReleaseBinaryScan.debug_symbols?('/tmp/dSYMs/App.app.dSYM/Contents/Resources/DWARF/App')
    refute ReleaseBinaryScan.debug_symbols?('/tmp/Payload/App.app/App')
  end

  def test_strings_sees_an_aligned_token
    padding = "\x00" * (64 * 1024)
    blob = "#{"\x00" * 32}#{TOKEN}#{"\x00" * 8}#{HOST}\x00#{padding}"
    Dir.mktmpdir do |dir|
      path = File.join(dir, 'App')
      File.binwrite(path, blob)
      hits = ReleaseBinaryScan.scan_path(path)
      rules = hits.map { |hit| hit[:rule] }
      assert_equal ['zendesk-token-before-host'], rules
    end
  end

  def test_strings_failure_is_an_error
    Dir.mktmpdir do |dir|
      error = assert_raises(RuntimeError) { ReleaseBinaryScan.strings_of(dir) }
      assert_match(/strings failed/, error.message)
    end
  end

  def test_archive_without_a_binary_fails
    Dir.mktmpdir do |dir|
      note = File.join(dir, 'readme.txt')
      File.write(note, 'hello')
      archive = File.join(dir, 'App.ipa')
      _out, status = Open3.capture2('/usr/bin/zip', '-q', '-j', archive, note)
      assert status.success?, 'zip failed'
      error = assert_raises(RuntimeError) { ReleaseBinaryScan.scan_path(archive) }
      assert_match(/no binaries/, error.message)
    end
  end
end
