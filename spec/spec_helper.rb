$LOAD_PATH.unshift File.expand_path '../../lib', __FILE__

require 'pry'
require 'faker'
require 'simplecov'
require 'coveralls'

SimpleCov.start
Coveralls.wear!

require 'mandrill_batch_mailer'
require 'mandrill_batch_mailer/base_mailer'

RSpec.configure do |config|
  config.order = 'random'
end
