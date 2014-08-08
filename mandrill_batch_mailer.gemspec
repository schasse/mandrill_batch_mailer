$LOAD_PATH.push File.expand_path('../lib', __FILE__)

require 'mandrill_batch_mailer/version'

Gem::Specification.new do |s|
  s.name        = 'mandrill_batch_mailer'
  s.version     = MandrillBatchMailer::VERSION
  s.authors     = ['schasse']
  s.email       = ['sebastian.schasse@gapfish.com']
  s.homepage    = 'http://github.com/schasse/mandrill_batch_mailer'
  s.summary     = 'Send batched Mails via Mandrill API'
  s.description = 'Send batched Mails via Mandrill API'

  s.files = Dir['{lib}/**/*'] +
    ['MIT-LICENSE', 'Rakefile', 'README.md']
  s.test_files = Dir['spec/**/*']

  s.add_runtime_dependency 'activesupport'

  s.add_development_dependency 'rspec', '~> 3.0.0'
  s.add_development_dependency 'faker'
  s.add_development_dependency 'travis'
  s.add_development_dependency 'simplecov'
  s.add_development_dependency 'coveralls'
  s.add_development_dependency 'rubocop'
  s.add_development_dependency 'cane'
  s.add_development_dependency 'pry'
end
