# mandrill_batch_mailer

[![Code Coverage](https://coveralls.io/repos/schasse/mandrill_batch_mailer/badge.png?branch=master)](https://coveralls.io/r/schasse/mandrill_batch_mailer)
[![Build Status](https://travis-ci.org/schasse/mandrill_batch_mailer.png?branch=master)](https://travis-ci.org/schasse/mandrill_batch_mailer)


Send batched Mails via Mandrill API.

## INSTALLATION

    gem install mandrill_batch_mailer

## CONFIGURATION

    # config/mandrill_batch_mailer.rb

    MandrillBatchMailer.configure do |config|
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

      # Set your from e-mail address and name
      config.from_email = 'mail@my-app.com'
      config.from_name = 'My App'
    end


## EXAMPLE

    # config/locales/en.yml

    en:
      mandrill:
        shared_translations:
          address_name: 'My App'
          address_street: '89 Colin P Kelly Jr St'
          address_zip: 'San Francisco, CA 94107'
          address_state: 'United States'
        welcome_mailer:
          welcome:
            subject: 'Welcome to our App!'
            welcome_to_app: 'welcome to our App.'
            cheers: 'Cheers Your App-Team''
        mass_mailer:
          mass_mail:
            subject: 'This is a mass mail'
            be_awesome: 'let's be awesome!'
            cheers: 'Cheers Your App-Team''

    # app/mailers/mandrill/welcome_mailer.rb

    class Mandrill::WelcomeMailer < MandrillBatchMailer::BaseMailer
      def welcome(user_id)
        @user = User.find user_id
        mail to: welcome_merge_vars
      end

      private

      def welcome_merge_vars
        {
          @user.email => {
            user_salutation: @user.salutation
          }
        }
      end
    end

    # app/mailers/mandrill/mass_mailer.rb

    class Mandrill::MassMailer < MandrillBatchMailer::BaseMailer

      def mass_mail(user_ids)
        @users = User.find user_ids
        mail to: mass_mail_merge_vars
      end

      private

      def mass_mail_merge_vars
        @users.map do |user|
          [user.email,
            {
              user_salutation: user.salutation
            }
          ]
        end.to_h
      end
    end
