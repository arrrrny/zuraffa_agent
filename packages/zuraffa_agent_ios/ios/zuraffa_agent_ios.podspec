Pod::Spec.new do |s|
  s.name             = 'zuraffa_agent_ios'
  s.version          = '0.1.0'
  s.summary          = 'iOS implementation of the zuraffa_agent AgentPlatform seam.'
  s.description      = 'Application Support home + Keychain secure store (spec 115).'
  s.homepage         = 'https://zuraffa.com'
  s.license          = { :type => 'MIT', :file => '../LICENSE' }
  s.author           = { 'Ahmet TOK' => 'https://zuraffa.com' }
  s.source           = { :path => '.' }
  s.platform = :ios, '13.0'
  s.dependency 'Flutter'
  s.source_files = 'Classes/**/*'
end
