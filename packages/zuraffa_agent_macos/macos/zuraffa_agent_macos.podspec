Pod::Spec.new do |s|
  s.name             = 'zuraffa_agent_macos'
  s.version          = '0.1.0'
  s.summary          = 'macOS implementation of the zuraffa_agent AgentPlatform seam.'
  s.description      = 'Application Support home + Keychain secure store (spec 115).'
  s.homepage         = 'https://zuraffa.com'
  s.license          = { :type => 'MIT', :file => '../LICENSE' }
  s.author           = { 'Ahmet TOK' => 'https://zuraffa.com' }
  s.source           = { :path => '.' }
  s.platform = :osx, '10.15'
  s.osx.deployment_target = '10.15'
  s.dependency 'Flutter'
  s.source_files = 'Classes/**/*'
end
