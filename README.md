# mandrill_batch_mailer

[![Code Coverage](https://coveralls.io/repos/schasse/mandrill_batch_mailer/badge.png?branch=master)](https://coveralls.io/r/schasse/mandrill_batch_mailer)
[![Build Status](https://travis-ci.org/schasse/mandrill_batch_mailer.png?branch=master)](https://travis-ci.org/schasse/mandrill_batch_mailer)


Send batched Mails via Mandrill API.

## INSTALLATION

    gem install mandrill_batch_mailer

## CONFIGURATION

    # config/mandrill_batch_mailer.rb

    MandrillBatchMailer.config do |config|
      # enable sending mails via the Mandrill API, default is false
      config.perform_deliveries = true

      # Enables interception of mails. Default is false
      config.intercept_recipients = true

      # Set a mail address you want your mails redirected to. '+#{nr}' will be
      # added for each recipient and the subject line includes the original mail
      # address.
      config.interception_base_mail = 'all-mails-to@some-domain.com'

      # Set to your Mandrill API Key you get from Mandrill.
      config.api_key = '3x4mpl3_k3y'
    end


## EXAMPLE

  TODO
