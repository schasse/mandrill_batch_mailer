require 'mandrill_batch_mailer/base_mailer'
require 'active_support/configurable'

module MandrillBatchMailer
  include ActiveSupport::Configurable

  ENDPOINT = 'https://mandrillapp.com/api/1.0/messages/'\
             'send-template.json'

  config_accessor :perform_deliveries,
                  :intercept_recipients,
                  :interception_base_mail,
                  :from_email,
                  :from_name,
                  :api_key

  self.perform_deliveries = false
  self.intercept_recipients = false
  self.interception_base_mail = ''

  attr_writer :logger

  def self.logger
    @logger ||= rails_logger || Logger.new(STDOUT)
  end

  def self.rails_logger
    defined?(Rails) && Rails.logger
  end
end
