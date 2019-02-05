# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

target 'MYJanken' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for MYJanken
  pod 'TesseractOCRiOS', '4.0.0'
  pod 'SwiftyJSON', '~> 3.1'

  target 'MYJankenTests' do
    inherit! :search_paths
    # Pods for testing
  end

  target 'MYJankenUITests' do
    inherit! :search_paths
    # Pods for testing
  end

  post_install do |installer|
    installer.pods_project.targets.each do |target|
        if target.name == 'TesseractOCRiOS'
            target.build_configurations.each do |config|
                config.build_settings['ENABLE_BITCODE'] = 'NO'
            end
            header_phase = target.build_phases().select do |phase|
                phase.is_a? Xcodeproj::Project::PBXHeadersBuildPhase
            end.first

            duplicated_header_files = header_phase.files.select do |file|
                file.display_name == 'config_auto.h'
            end

            duplicated_header_files.each do |file|
                header_phase.remove_build_file file
            end
        end
    end
  end

end
