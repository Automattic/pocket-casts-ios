# frozen_string_literal: true

# Generate iOS theme colours from exported CSV from Google Sheet
# To use: ruby generate_themes.rb themes.csv
require 'csv'

file_path_colors = './podcasts/ThemeColor.swift'
file_path_styles = './podcasts/ThemeStyle.swift'

class String
  def uncapitalize
    self[0, 1].downcase + self[1..]
  end
end

# Build an Xcode colour literal (which renders as a colour swatch in the editor)
# alongside a trailing comment with the HEX and RGB values for readability.
# `alpha` is a float in 0...1 and `opacity_label` (e.g. "10%") is appended to the
# comment when the colour isn't fully opaque. Returns [literal, comment].
def color_literal(hex_val, alpha = 1.0, opacity_label = nil)
  hex = hex_val.delete('#')
  red = hex[0, 2].to_i(16)
  green = hex[2, 2].to_i(16)
  blue = hex[4, 2].to_i(16)
  literal = "#colorLiteral(red: #{red / 255.0}, green: #{green / 255.0}, blue: #{blue / 255.0}, alpha: #{alpha})"
  comment = "// #{hex_val} (#{red},#{green},#{blue})"
  comment += " #{opacity_label}" unless opacity_label.nil?
  [literal, comment]
end

# Special filter overlay colours: these are functions of the runtime filter
# colour, so concrete-hex cases get a colour-literal swatch while the dynamic
# (`$filter` / blended) cases keep their computed expression.
def filter_theme_value(hex_val, opacity, token_name, theme_name)
  str = ''
  if ['filter', '$filter', '#filter'].include?(hex_val)
    # the ones without any custom opacity are easy
    if opacity == '100%' || opacity.nil? || opacity.empty?
      str = "
    static func #{token_name}#{theme_name}(filterColor: UIColor) -> UIColor {
        filterColor
    }\n"
    else
      # tokenize the filter colour to figure out what it should be
      # example string: filter 15% on white
      words = opacity.split

      actual_opacity = words[1].gsub('%', '')
      original_color = if words[3] == 'white'
                         'UIColor(hex: "#FFFFFF")'
                       elsif words[3].start_with?('#')
                         "UIColor(hex: \"#{words[3]}\")"
                       else
                         'UIColor(hex: "#000000")'
                       end
      overlay_color = "filterColor.withAlphaComponent(#{actual_opacity.to_f / 100.0})"

      str = "
    static func #{token_name}#{theme_name}(filterColor: UIColor) -> UIColor {
        UIColor.calculateColor(orgColor: #{original_color}, overlayColor: #{overlay_color})
    }\n"
    end
  else
    literal, comment = color_literal(hex_val)
    str = "
    static func #{token_name}#{theme_name}(filterColor: UIColor) -> UIColor { #{literal} } #{comment}\n"
  end
  str
end

# Special podcast overlay colours: same idea as the filter variants, computed
# from the runtime podcast colour, with concrete-hex cases rendered as swatches.
def podcast_theme_value(hex_val, opacity, token_name, theme_name)
  str = ''
  if ['podcast', '$podcast', '#podcast'].include?(hex_val)
    # the ones without any custom opacity are easy
    if opacity == '100%' || opacity.nil? || opacity.empty?
      str = "
    static func #{token_name}#{theme_name}(podcastColor: UIColor) -> UIColor {\n        podcastColor\n    }\n"
    elsif opacity.split.size == 1
      opacity = opacity.gsub('%', '')
      str = "
    static func #{token_name}#{theme_name}(podcastColor: UIColor) -> UIColor {
        podcastColor.withAlphaComponent(#{opacity.to_f / 100.0})
    }\n"
    else
      # tokenize the podcast colour to figure out what it should be
      # example string: podcast 15% on #3D3D3D
      words = opacity.split

      actual_opacity = words[1].gsub('%', '')
      original_color = "UIColor(hex: \"#{words[3]}\")"
      overlay_color = "podcastColor.withAlphaComponent(#{actual_opacity.to_f / 100.0})"

      str = "
    static func #{token_name}#{theme_name}(podcastColor: UIColor) -> UIColor {
        UIColor.calculateColor(orgColor: #{original_color}, overlayColor: #{overlay_color})
    }\n"
    end
  elsif opacity == '100%' || opacity.nil? || opacity.empty?
    literal, comment = color_literal(hex_val)
    str = "
    static func #{token_name}#{theme_name}(podcastColor: UIColor) -> UIColor { #{literal} } #{comment}\n"
  elsif opacity.split.size == 1
    pct = opacity.gsub('%', '')
    literal, comment = color_literal(hex_val, pct.to_f / 100.0, "#{pct}%")
    str = "
    static func #{token_name}#{theme_name}(podcastColor: UIColor) -> UIColor { #{literal} } #{comment}\n"
  end
  str
end

def write_theme_value(hex_val, opacity, token_name, file_path, theme_name)
  if token_name.start_with?('filterU') || token_name.start_with?('filterI') || token_name.start_with?('filterT')
    File.write(file_path, filter_theme_value(hex_val, opacity, token_name, theme_name), mode: 'a')
    return
  elsif token_name.start_with?('podcast') || token_name.start_with?('playerBackground') || token_name.start_with?('playerHighlight')
    File.write(file_path, podcast_theme_value(hex_val, opacity, token_name, theme_name), mode: 'a')
    return
  end

  unless hex_val.start_with?('#')
    puts "Invalid hex value found #{hex_val}, found in #{token_name} ignoring"
    return
  end

  if opacity == '100%' || opacity.nil? || opacity.empty?
    literal, comment = color_literal(hex_val)
  else
    pct = opacity.gsub('%', '')
    label = pct.strip.empty? ? nil : "#{pct.strip}%"
    literal, comment = color_literal(hex_val, pct.to_f / 100.0, label)
  end
  File.write(file_path, "    private static let #{token_name}#{theme_name}: UIColor = #{literal} #{comment}\n", mode: 'a')
end

File.truncate(file_path_colors, 0) if File.exist?(file_path_colors)
File.truncate(file_path_styles, 0) if File.exist?(file_path_styles)

File.write(file_path_colors,
           "import PocketCastsUtils\nimport PocketCastsServer\nimport UIKit\n\n// ************ WARNING AUTO GENERATED, DO NOT EDIT ************\nstruct ThemeColor {\n", mode: 'a')
File.write(file_path_styles, "// ************ WARNING AUTO GENERATED, DO NOT EDIT ************\nenum ThemeStyle {\n",
           mode: 'a')

index = 0
all_token_names = []
# Explicit encoding so the script works in locale-less environments
# (e.g. Xcode build phases), where Ruby defaults to US-ASCII.
CSV.foreach(ARGV[0], encoding: 'bom|utf-8') do |row|
  token_name = row[0]

  light_hex_value = row[2]
  light_opacity = row[3]

  dark_hex_value = row[4]
  dark_opacity = row[5]

  extra_dark_hex_value = row[6]
  extra_dark_opacity = row[7]

  classic_light_hex_value = row[8]
  classic_light_opacity = row[9]

  # These are unused but left here for reference and future use
  # classic_dark_hex_value = row[10]
  # classic_dark_opacity = row[11]

  electric_hex_value = row[12]
  electric_opacity = row[13]

  indigo_hex_value = row[14]
  indigo_opacity = row[15]

  rosé_hex_value = row[16]
  rosé_opacity = row[17]

  high_contrast_light_hex_value = row[18]
  high_contrast_light_opacity = row[19]

  high_contrast_dark_hex_value = row[20]
  high_contrast_dark_opacity = row[21]

  unless token_name.nil? || token_name == ' ' || token_name == 'Token' || light_hex_value.nil? || dark_hex_value.nil?
    token_name = token_name.gsub('$', '').split('-').collect(&:capitalize).join.uncapitalize
    all_token_names << token_name

    if index.zero?
      File.write(file_path_styles, "    case #{token_name},\n", mode: 'a')
    else
      File.write(file_path_styles, "         #{token_name},\n", mode: 'a')
    end

    write_theme_value(light_hex_value, light_opacity, token_name, file_path_colors, 'Light')
    write_theme_value(dark_hex_value, dark_opacity, token_name, file_path_colors, 'Dark')
    write_theme_value(extra_dark_hex_value, extra_dark_opacity, token_name, file_path_colors, 'ExtraDark')
    write_theme_value(classic_light_hex_value, classic_light_opacity, token_name, file_path_colors, 'ClassicLight')
    write_theme_value(electric_hex_value, electric_opacity, token_name, file_path_colors, 'Electric')
    write_theme_value(indigo_hex_value, indigo_opacity, token_name, file_path_colors, 'Indigo')
    write_theme_value(rosé_hex_value, rosé_opacity, token_name, file_path_colors, 'Rosé')
    write_theme_value(high_contrast_light_hex_value, high_contrast_light_opacity, token_name, file_path_colors,
                      'ContrastLight')
    write_theme_value(high_contrast_dark_hex_value, high_contrast_dark_opacity, token_name, file_path_colors,
                      'ContrastDark')

    index += 1
  end
end

File.write(file_path_colors, "\n\n", mode: 'a')
all_token_names.each do |token|
  token_str = if token.start_with?('podcast') || token.start_with?('playerBackground') || token.start_with?('playerHighlight')
                "    static func #{token}(podcastColor: UIColor, for theme: Theme.ThemeType? = nil) -> UIColor {
        let theme = theme ?? Theme.sharedTheme.activeTheme
        switch theme {
        case .light:
            return ThemeColor.#{token}Light(podcastColor: podcastColor)
        case .dark:
            return ThemeColor.#{token}Dark(podcastColor: podcastColor)
        case .extraDark:
            return ThemeColor.#{token}ExtraDark(podcastColor: podcastColor)
        case .electric:
            return ThemeColor.#{token}Electric(podcastColor: podcastColor)
        case .classic:
            return ThemeColor.#{token}ClassicLight(podcastColor: podcastColor)
        case .indigo:
            return ThemeColor.#{token}Indigo(podcastColor: podcastColor)
        case .rosé:
            return ThemeColor.#{token}Rosé(podcastColor: podcastColor)
        case .contrastLight:
            return ThemeColor.#{token}ContrastLight(podcastColor: podcastColor)
        case .contrastDark:
            return ThemeColor.#{token}ContrastDark(podcastColor: podcastColor)
        }
    }\n\n"
              elsif token.start_with?('filterU') || token.start_with?('filterI') || token.start_with?('filterT')
                "    static func #{token}(filterColor: UIColor, for theme: Theme.ThemeType? = nil) -> UIColor {
        let theme = theme ?? Theme.sharedTheme.activeTheme
        switch theme {
        case .light:
            return ThemeColor.#{token}Light(filterColor: filterColor)
        case .dark:
            return ThemeColor.#{token}Dark(filterColor: filterColor)
        case .extraDark:
            return ThemeColor.#{token}ExtraDark(filterColor: filterColor)
        case .electric:
            return ThemeColor.#{token}Electric(filterColor: filterColor)
        case .classic:
            return ThemeColor.#{token}ClassicLight(filterColor: filterColor)
        case .indigo:
            return ThemeColor.#{token}Indigo(filterColor: filterColor)
        case .rosé:
            return ThemeColor.#{token}Rosé(filterColor: filterColor)
        case .contrastLight:
            return ThemeColor.#{token}ContrastLight(filterColor: filterColor)
        case .contrastDark:
            return ThemeColor.#{token}ContrastDark(filterColor: filterColor)
        }
    }\n\n"
              else
                "    static func #{token}(for theme: Theme.ThemeType? = nil) -> UIColor {
        let theme = theme ?? Theme.sharedTheme.activeTheme
        switch theme {
        case .light:
            return ThemeColor.#{token}Light
        case .dark:
            return ThemeColor.#{token}Dark
        case .extraDark:
            return ThemeColor.#{token}ExtraDark
        case .electric:
            return ThemeColor.#{token}Electric
        case .classic:
            return ThemeColor.#{token}ClassicLight
        case .indigo:
            return ThemeColor.#{token}Indigo
        case .rosé:
            return ThemeColor.#{token}Rosé
        case .contrastLight:
            return ThemeColor.#{token}ContrastLight
        case .contrastDark:
            return ThemeColor.#{token}ContrastDark
        }
    }\n\n"
              end
  File.write(file_path_colors, token_str, mode: 'a')
end

File.truncate(file_path_colors, File.size(file_path_colors) - 1) # collapse the blank line left by the last token
File.write(file_path_colors, "}\n", mode: 'a')

File.truncate(file_path_styles, File.size(file_path_styles) - 2) # remove the trailing comma
File.write(file_path_styles, "\n}\n", mode: 'a')
