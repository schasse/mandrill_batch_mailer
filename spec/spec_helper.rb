$LOAD_PATH.unshift File.expand_path '../../lib', __FILE__

require 'simplecov'
SimpleCov.start

require 'coveralls'
Coveralls.wear!

# Dir[Rails.root.join('spec/support/**/*.rb')].each { |f| require f }

RSpec.configure do |config|
  config.order = 'random'
end
