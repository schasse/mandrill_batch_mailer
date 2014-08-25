require 'active_support'
require 'active_support/inflector'
require 'active_support/core_ext/object/try'

module MandrillBatchMailer
  class BaseMailer
    private

      attr_accessor :caller_method_name

    public

      def initialize(method)
        self.caller_method_name = method
      end

      def mail(to: nil)
        @tos = tos_from(to)
        send_template mandrill_parameters
      end

      # feel free to override
      def from_email
        MandrillBatchMailer.from_email
      end

      # feel free to override
      def from_name
        MandrillBatchMailer.from_name || ''
      end

      # feel free to override
      def tags
        ["#{template_name}"]
      end

      class << self
        # do it just as ActionMailer
        def method_missing(method, *args)
          mailer = new method
          if mailer.respond_to? method
            mailer.public_send(method, *args)
          else
            super method, *args
          end
        end
      end

    protected

      def scope
        "#{class_name.underscore.gsub('/', '.')}.#{caller_method_name}"
      end

    private

      # rubocop:disable MethodLength
      def mandrill_parameters
        {
          key: MandrillBatchMailer.api_key,
          template_name: template_name,
          template_content: [],
          message: {
            subject: subject,
            from_email: from_email,
            from_name: from_name,
            to: to,
            important: false,
            track_opens: nil,
            track_clicks: nil,
            inline_css: true,
            url_strip_qs: nil,
            preserve_recipients: false,
            view_content_link: nil,
            tracking_domain: nil,
            signing_domain: nil,
            return_path_domain: nil,
            merge: true,
            global_merge_vars: global_merge_vars,
            merge_vars: merge_vars,
            tags: tags
          },
          async: true
        }.deep_merge(_default)
      end
      # rubocop:enable MethodLength

      def _default
        given_defaults = (respond_to?(:default, true) && default) || {}
        if MandrillBatchMailer.intercept_recipients
          given_defaults[:message].try(:delete, :to)
        end
        given_defaults
      end

      def template_name
        "#{class_name.underscore}_#{caller_method_name}".split('/').last
          .gsub '_', '-'
      end

      def subject
        '*|subject|*'
      end

      def to
        if MandrillBatchMailer.intercept_recipients
          @tos.keys.size.times.map do |i|
            { email: MandrillBatchMailer
                .interception_base_mail.sub('@', "+#{i}@") }
          end
        else
          @tos.keys.map { |to_email| { email: to_email } }
        end
      end

      def global_merge_vars
        merge_vars_from(translations.merge(shared_translations))
      end

      def merge_vars
        @tos.each_with_index.map do |to, i|
          to_email, vars = to.to_a
          if MandrillBatchMailer.intercept_recipients
            intercepted_merge_vars(to_email, vars, i)
          else
            { rcpt: to_email,  vars: merge_vars_from(vars) }
          end
        end
      end

      def intercepted_merge_vars(to_email, vars, i)
        subject = vars[:subject] || translations[:subject]
        {
          rcpt: MandrillBatchMailer.interception_base_mail.sub('@', "+#{i}@"),
          vars: merge_vars_from(vars.merge(subject: "#{to_email} #{subject}"))
        }
      end

      ## HELPER METHODS ##

      # @return [Hash]
      #   p.e. { 'some@mail.ch' => { a_variable: 'Hello' } }
      def tos_from(to)
        case to
        when String
          { to => {} }
        when Array
          to.map { |single_to| [single_to, {}] }.to_h
        when Hash
          to
        else
          to.to_h
        end
      end

      def translations
        I18n.t scope, default: {}
      end

      def class_name
        self.class.to_s
      end

      def shared_translations
        I18n.t(
          "#{class_name.deconstantize.underscore}.shared_translations",
          default: {})
      end

      def merge_vars_from(translations)
        translations.map do |key, translation|
          { name: key, content: translation }
        end
      end

      def send_template(params)
        if MandrillBatchMailer.perform_deliveries
          RestClient.post MandrillBatchMailer::ENDPOINT, params.to_json
          params
        else
          log_sending(params)
          params
        end
      end

      def log_sending(params)
        params_inspect =
          if defined? AwesomePrint
            params.ai
          else
            params.inspect
          end
        MandrillBatchMailer.logger
          .info "Sending Mandrill Mail: #{params_inspect}"
      end
  end
end
