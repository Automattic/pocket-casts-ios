# frozen_string_literal: true

require 'minitest/autorun'
require 'tmpdir'
require_relative 'scan_release_binary'

TOKEN = 'ZdTestTokenNotReal0123456789abcdEF'
HOST = 'https://acme.zendesk.com'

class ReleaseBinaryScanTest < Minitest::Test
  def test_rejects_identifiers_and_hex
    refute ReleaseBinaryScan.token_shaped?('loggingEncryptionKey')
    refute ReleaseBinaryScan.token_shaped?('0123456789abcdef0123456789abcdef')
    assert ReleaseBinaryScan.token_shaped?(TOKEN)
  end

  def test_alignment_gap_counts_as_packed
    packed = [[100, TOKEN], [100 + TOKEN.bytesize + 8, HOST]]
    hits = ReleaseBinaryScan.scan_table(packed)
    assert_equal ['zendesk-token-before-host'], hits.map { |hit| hit[:rule] }
    refute_includes hits.first[:redacted], TOKEN

    far = [[100, TOKEN], [100 + TOKEN.bytesize + 17, HOST]]
    assert_empty ReleaseBinaryScan.scan_table(far)
  end

  def test_email_token_literal
    hits = ReleaseBinaryScan.scan_table([[0, "user@example.com/token:#{TOKEN}"]])
    assert_equal ['zendesk-email-token'], hits.map { |hit| hit[:rule] }
  end

  def test_skips_debug_symbol_bundles
    assert ReleaseBinaryScan.debug_symbols?('/tmp/dSYMs/App.app.dSYM/Contents/Resources/DWARF/App')
    refute ReleaseBinaryScan.debug_symbols?('/tmp/Payload/App.app/App')
  end

  def test_strings_sees_an_aligned_token
    blob = ("\x00" * 32) + TOKEN + ("\x00" * 8) + HOST + "\x00"
    blob += "\x00" * (64 * 1024)
    Dir.mktmpdir do |dir|
      path = File.join(dir, 'App')
      File.binwrite(path, blob)
      hits = ReleaseBinaryScan.scan_path(path)
      assert_equal ['zendesk-token-before-host'], hits.map { |hit| hit[:rule] }
    end
  end
end
