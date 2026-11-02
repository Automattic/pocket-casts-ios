# frozen_string_literal: true

require 'open3'
require 'tmpdir'

# Unpack an `.ipa` or `.zip` and yield each scannable binary.
module ReleaseBinaryArchive
  module_function

  def each_binary(path, &block)
    return block.call(path) unless archive?(path)

    Dir.mktmpdir('release-binary-scan') do |dir|
      extract(path, dir)
      binaries = binaries_under(dir)
      raise "no binaries in #{path}" if binaries.empty?

      binaries.each(&block)
    end
  end

  def archive?(path)
    path.end_with?('.ipa', '.zip')
  end

  def binaries_under(root)
    Dir.glob(File.join(root, '**', '*')).select { |candidate| ReleaseBinaryScan.binary?(candidate) }
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
