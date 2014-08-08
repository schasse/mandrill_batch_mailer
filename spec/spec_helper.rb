$LOAD_PATH.unshift File.expand_path '../../lib', __FILE__
require 'mandrill_batch_mailer'
require 'mandrill_batch_mailer/base_mailer'

require 'pry'
require 'faker'
require 'simplecov'
require 'coveralls'

SimpleCov.start

Coveralls.wear!

# Dir[Rails.root.join('spec/support/**/*.rb')].each { |f| require f }

RSpec.configure do |config|
  config.order = 'random'
end
