#!/usr/bin/env ruby
# frozen_string_literal: true

objc = `find ./podcasts/ -name "*.m" -print0 | xargs -0 wc -l | tail -n1 | awk '{print $1}'`.chomp.to_i
swift = `find ./podcasts/ -name "*.swift" -print0 | xargs -0 wc -l | tail -n1 | awk '{print $1}'`.chomp.to_i
total = objc + swift
swift_percent = ((swift.to_f / total) * 10_000).to_i.to_f / 100

output = "#{objc} Objective-C\n#{swift} Swift\n#{total} Total\n\n#{swift_percent}% Swift"

puts output

`osascript -e 'display notification "#{swift_percent}% Swift\n#{total} Total lines" with title "Pocket Casts"'`
