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

def write_theme_value(hex_val, opacity, token_name, file_path, theme_name)
  if token_name.start_with?('filterU') || token_name.start_with?('filterI') || token_name.start_with?('filterT')
    str = ''
    # deal with special filter overlay colours
    if ['filter', '$filter', '#filter'].include?(hex_val)
      # the ones without any custom opacity are easy
      if opacity == '100%' || opacity.nil? || opacity.empty?
        str = "static func #{token_name}#{theme_name}(filterColor: UIColor) -> UIColor {
                          return filterColor
                       }\n\n"
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

        str = "static func #{token_name}#{theme_name}(filterColor: UIColor) -> UIColor {
                           return UIColor.calculateColor(orgColor: #{original_color}, overlay_color: #{overlay_color})
                       }\n\n"
      end

    else
      str = "static func #{token_name}#{theme_name}(filterColor: UIColor) -> UIColor { return UIColor(hex: \"#{hex_val}\") }\n\n"
    end

    File.write(file_path, str, mode: 'a')
    return
  elsif token_name.start_with?('podcast') || token_name.start_with?('playerBackground') || token_name.start_with?('playerHighlight')
    str = ''
    # deal with special podcast overlay colours
    if ['podcast', '$podcast', '#podcast'].include?(hex_val)
      # the ones without any custom opacity are easy
      if opacity == '100%' || opacity.nil? || opacity.empty?
        str = "static func #{token_name}#{theme_name}(podcastColor: UIColor) -> UIColor {
                          return podcastColor
                       }\n\n"
      elsif opacity.split.size == 1
        opacity = opacity.gsub('%', '')
        str = "static func #{token_name}#{theme_name}(podcastColor: UIColor) -> UIColor {
                          return podcastColor.withAlphaComponent(#{opacity.to_f / 100.0})
                       }\n\n"
      else
        # tokenize the podcast colour to figure out what it should be
        # example string: podcast 15% on #3D3D3D
        words = opacity.split

        actual_opacity = words[1].gsub('%', '')
        original_color = "UIColor(hex: \"#{words[3]}\")"
        overlay_color = "podcastColor.withAlphaComponent(#{actual_opacity.to_f / 100.0})"

        str = "static func #{token_name}#{theme_name}(podcastColor: UIColor) -> UIColor {
                           return UIColor.calculateColor(orgColor: #{original_color}, overlay_color: #{overlay_color})
                       }\n\n"
      end
    elsif opacity == '100%' || opacity.nil? || opacity.empty?
      str = "static func #{token_name}#{theme_name}(podcastColor: UIColor) -> UIColor { return UIColor(hex: \"#{hex_val}\") }\n\n"
    elsif opacity.split.size == 1
      opacity = opacity.gsub('%', '')
      str = "static func #{token_name}#{theme_name}(podcastColor: UIColor) -> UIColor {
                          return UIColor(hex: \"#{hex_val}\").withAlphaComponent(#{opacity.to_f / 100.0})
                       }\n\n"
    end

    File.write(file_path, str, mode: 'a')
    return
  end

  unless hex_val.start_with?('#')
    puts "Invalid hex value found #{hex_val}, found in #{token_name} ignoring"
    return
  end

  variable_str = "	private static let #{token_name}#{theme_name} = UIColor(hex: \"#{hex_val}\")"
  if opacity == '100%' || opacity.nil? || opacity.empty?
    File.write(file_path, "#{variable_str}\n", mode: 'a')
  else
    opacity = opacity.gsub('%', '')
    File.write(file_path, "#{variable_str}.withAlphaComponent(#{opacity.to_f / 100.0}) \n", mode: 'a')
  end
end

File.truncate(file_path_colors, 0) if File.exist?(file_path_colors)
File.truncate(file_path_styles, 0) if File.exist?(file_path_styles)

File.write(file_path_colors,
           "import Utils\n\n// ************ WARNING AUTO GENERATED, DO NOT EDIT ************\nstruct ThemeColor {\n", mode: 'a')
File.write(file_path_styles, "// ************ WARNING AUTO GENERATED, DO NOT EDIT ************\nenum ThemeStyle {\n",
           mode: 'a')

index = 0
all_token_names = []
CSV.foreach(ARGV[0]) do |row|
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

  radioactive_hex_value = row[16]
  radioactive_opacity = row[17]

  rosé_hex_value = row[18]
  rosé_opacity = row[19]

  high_contrast_light_hex_value = row[20]
  high_contrast_light_opacity = row[21]

  high_contrast_dark_hex_value = row[22]
  high_contrast_dark_opacity = row[23]

  unless token_name.nil? || token_name == ' ' || token_name == 'Token' || light_hex_value.nil? || dark_hex_value.nil?
    token_name = token_name.gsub('$', '').split('-').collect(&:capitalize).join.uncapitalize
    all_token_names << token_name

    if index.zero?
      File.write(file_path_styles, "    case #{token_name},\n", mode: 'a')
    else
      File.write(file_path_styles, "    #{token_name},\n", mode: 'a')
    end

    write_theme_value(light_hex_value, light_opacity, token_name, file_path_colors, 'Light')
    write_theme_value(dark_hex_value, dark_opacity, token_name, file_path_colors, 'Dark')
    write_theme_value(extra_dark_hex_value, extra_dark_opacity, token_name, file_path_colors, 'ExtraDark')
    write_theme_value(classic_light_hex_value, classic_light_opacity, token_name, file_path_colors, 'ClassicLight')
    write_theme_value(electric_hex_value, electric_opacity, token_name, file_path_colors, 'Electric')
    write_theme_value(indigo_hex_value, indigo_opacity, token_name, file_path_colors, 'Indigo')
    write_theme_value(radioactive_hex_value, radioactive_opacity, token_name, file_path_colors, 'Radioactive')
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
                case .radioactive:
                    return ThemeColor.#{token}Radioactive(podcastColor: podcastColor)
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
                case .radioactive:
                    return ThemeColor.#{token}Radioactive(filterColor: filterColor)
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
                case .radioactive:
                    return ThemeColor.#{token}Radioactive
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

File.write(file_path_colors, '}', mode: 'a')

File.truncate(file_path_styles, File.size(file_path_styles) - 2) # remove the trailing comma
File.write(file_path_styles, "\n}", mode: 'a')
