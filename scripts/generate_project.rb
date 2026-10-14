#!/usr/bin/env ruby
# Generates Minimal.xcodeproj from the folders in this repository.
#
#   gem install xcodeproj
#   ruby scripts/generate_project.rb
#
# The generated project is committed, so you only need this after adding or
# removing source files.

require 'fileutils'
require 'xcodeproj'

ROOT = File.expand_path('..', __dir__)
# Work with relative paths so the output (including UUIDs) is identical on every machine.
Dir.chdir(ROOT)
PROJECT_PATH = 'Minimal.xcodeproj'
DEPLOYMENT_TARGET = '17.0'

FileUtils.rm_rf(PROJECT_PATH)
project = Xcodeproj::Project.new(PROJECT_PATH, false, 60)
project.root_object.attributes['LastSwiftUpdateCheck'] = '2600'
project.root_object.attributes['LastUpgradeCheck'] = '2600'
project.root_object.attributes['BuildIndependentTargetsInParallel'] = 'YES'
project.root_object.development_region = 'pl'
project.root_object.known_regions = %w[pl en Base]

# ── Groups mirroring the folders ────────────────────────────────────────────

main_group = project.main_group

def add_tree(project, parent_group, dir, files_out)
  group = parent_group.new_group(File.basename(dir), File.basename(dir))
  Dir.children(dir).sort.each do |name|
    path = File.join(dir, name)
    if File.directory?(path) && !name.end_with?('.xcassets')
      add_tree(project, group, path, files_out)
    else
      ref = group.new_reference(name)
      ref.last_known_file_type = 'folder.assetcatalog' if name.end_with?('.xcassets')
      files_out << ref
    end
  end
  group
end

app_refs = []
shared_refs = []
widget_refs = []
config_refs = []
profile_refs = []

add_tree(project, main_group, 'Minimal', app_refs)
add_tree(project, main_group, 'Shared', shared_refs)
add_tree(project, main_group, 'MinimalWidget', widget_refs)
add_tree(project, main_group, 'Config', config_refs)
add_tree(project, main_group, 'Profiles', profile_refs)

xcconfig = config_refs.find { |ref| ref.path == 'Signing.xcconfig' }
raise 'Config/Signing.xcconfig missing' unless xcconfig

# ── Project-level build settings ────────────────────────────────────────────

project.build_configurations.each do |config|
  config.base_configuration_reference = xcconfig
  s = config.build_settings
  s['IPHONEOS_DEPLOYMENT_TARGET'] = DEPLOYMENT_TARGET
  s['SDKROOT'] = 'iphoneos'
  s['SWIFT_VERSION'] = '5.0'
  s['CLANG_ENABLE_MODULES'] = 'YES'
  s['ENABLE_STRICT_OBJC_MSGSEND'] = 'YES'
  s['ENABLE_USER_SCRIPT_SANDBOXING'] = 'YES'
  s['GCC_NO_COMMON_BLOCKS'] = 'YES'
  s['LOCALIZATION_PREFERS_STRING_CATALOGS'] = 'YES'
  s['ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS'] = 'YES'
  if config.name == 'Debug'
    s['ONLY_ACTIVE_ARCH'] = 'YES'
    s['DEBUG_INFORMATION_FORMAT'] = 'dwarf'
    s['ENABLE_TESTABILITY'] = 'YES'
    s['SWIFT_OPTIMIZATION_LEVEL'] = '-Onone'
    s['SWIFT_ACTIVE_COMPILATION_CONDITIONS'] = 'DEBUG $(inherited)'
    s['GCC_OPTIMIZATION_LEVEL'] = '0'
  else
    s['DEBUG_INFORMATION_FORMAT'] = 'dwarf-with-dsym'
    s['SWIFT_COMPILATION_MODE'] = 'wholemodule'
    s['VALIDATE_PRODUCT'] = 'YES'
  end
end

# ── Targets ─────────────────────────────────────────────────────────────────

def source?(ref)
  ref.path.end_with?('.swift')
end

def resource?(ref)
  ref.path.end_with?('.xcassets', '.mobileconfig', '.xcprivacy')
end

app = project.new_target(:application, 'Minimal', :ios, DEPLOYMENT_TARGET)
widget = project.new_target(:app_extension, 'MinimalWidget', :ios, DEPLOYMENT_TARGET)

# System frameworks are linked automatically through Swift imports; drop the explicit
# Foundation.framework reference the template adds (it points at an SDK-relative path).
[app, widget].each do |target|
  target.frameworks_build_phase.files.to_a.each(&:remove_from_project)
end
frameworks_group = project.main_group.children.find { |child| child.display_name == 'Frameworks' }
frameworks_group&.remove_from_project

# Fail early with a clear message when the edition is misspelled.
check = app.new_shell_script_build_phase('Check MINIMAL_EDITION')
check.shell_script = <<~SH
  case "$MINIMAL_EDITION" in
    Full|Free) ;;
    *) echo "error: MINIMAL_EDITION must be Full or Free (Config/Signing.xcconfig), got '$MINIMAL_EDITION'"; exit 1 ;;
  esac
SH
check.always_out_of_date = '1'
app.build_phases.move(check, 0)

app.add_file_references((app_refs + shared_refs).select { |ref| source?(ref) })
(app_refs + profile_refs).select { |ref| resource?(ref) }.each { |ref| app.resources_build_phase.add_file_reference(ref) }
widget.add_file_references((widget_refs + shared_refs).select { |ref| source?(ref) })
widget_refs.select { |ref| resource?(ref) }.each { |ref| widget.resources_build_phase.add_file_reference(ref) }

common = {
  'CODE_SIGN_STYLE' => 'Automatic',
  'CURRENT_PROJECT_VERSION' => '1',
  'MARKETING_VERSION' => '1.0',
  'GENERATE_INFOPLIST_FILE' => 'NO',
  'SWIFT_EMIT_LOC_STRINGS' => 'YES',
  'TARGETED_DEVICE_FAMILY' => '1',
  'SUPPORTS_MACCATALYST' => 'NO',
  'SUPPORTED_PLATFORMS' => 'iphoneos iphonesimulator',
  'SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD' => 'NO',
  'SUPPORTS_XR_DESIGNED_FOR_IPHONE_IPAD' => 'NO',
  'IPHONEOS_DEPLOYMENT_TARGET' => DEPLOYMENT_TARGET,
  'SWIFT_VERSION' => '5.0',
}

app.build_configurations.each do |config|
  s = config.build_settings
  s.merge!(common)
  s['PRODUCT_NAME'] = '$(TARGET_NAME)'
  s['PRODUCT_BUNDLE_IDENTIFIER'] = '$(APP_BUNDLE_ID)'
  s['INFOPLIST_FILE'] = 'Minimal/Info.plist'
  s['CODE_SIGN_ENTITLEMENTS'] = 'Minimal/Minimal-$(MINIMAL_EDITION).entitlements'
  s['ASSETCATALOG_COMPILER_APPICON_NAME'] = 'AppIcon'
  s['ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME'] = 'AccentColor'
  s['ASSETCATALOG_COMPILER_INCLUDE_ALL_APPICON_ASSETS'] = 'NO'
  s['ENABLE_PREVIEWS'] = 'YES'
  s['LD_RUNPATH_SEARCH_PATHS'] = ['$(inherited)', '@executable_path/Frameworks']
  s.delete('CODE_SIGN_IDENTITY[sdk=iphoneos*]')
end

widget.build_configurations.each do |config|
  s = config.build_settings
  s.merge!(common)
  s['PRODUCT_NAME'] = '$(TARGET_NAME)'
  s['PRODUCT_BUNDLE_IDENTIFIER'] = '$(WIDGET_BUNDLE_ID)'
  s['INFOPLIST_FILE'] = 'MinimalWidget/Info.plist'
  s['CODE_SIGN_ENTITLEMENTS'] = 'MinimalWidget/MinimalWidget.entitlements'
  s['SKIP_INSTALL'] = 'YES'
  s['APPLICATION_EXTENSION_API_ONLY'] = 'YES'
  s['LD_RUNPATH_SEARCH_PATHS'] = ['$(inherited)', '@executable_path/Frameworks', '@executable_path/../../Frameworks']
  s.delete('CODE_SIGN_IDENTITY[sdk=iphoneos*]')
end

# Embed the widget in the app.
app.add_dependency(widget)
embed = app.new_copy_files_build_phase('Embed Foundation Extensions')
embed.symbol_dst_subfolder_spec = :plug_ins
build_file = embed.add_file_reference(widget.product_reference, true)
build_file.settings = { 'ATTRIBUTES' => ['RemoveHeadersOnCopy'] }

# Target attributes (what Xcode writes when a target is created in the UI).
attributes = project.root_object.attributes
attributes['TargetAttributes'] ||= {}
[app, widget].each do |target|
  attributes['TargetAttributes'][target.uuid] = { 'CreatedOnToolsVersion' => '26.0' }
end

# Products group last, like Xcode does.
products = main_group.children.find { |child| child.display_name == 'Products' }
if products
  main_group.children.delete(products)
  main_group.children << products
end

project.predictabilize_uuids
project.save

# ── Shared scheme ───────────────────────────────────────────────────────────

scheme = Xcodeproj::XCScheme.new
scheme.add_build_target(app)
scheme.add_build_target(widget, false)
scheme.set_launch_target(app)
# Installing from Xcode should give people the fast, optimised build.
scheme.launch_action.build_configuration = 'Release'
scheme.archive_action.build_configuration = 'Release'
scheme.save_as(PROJECT_PATH, 'Minimal', true)

puts "Generated #{PROJECT_PATH}"
