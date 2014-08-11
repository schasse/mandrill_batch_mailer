require 'spec_helper'

describe MandrillBatchMailer::BaseMailer, :dbless do
  let(:user_dup) do
    -> do
      double locale: :de, email: Faker::Internet.email, first_name: Faker.name
    end
  end
  let(:user) do
    user_dup.call
  end
  let(:more_users) do
    2.times.map { user_dup.call } + [user]
  end

  let(:translations) do
    {
      mandrill_batch_mailer: {
        shared_translations: {
          salutation: 'Hello'
        },
        test_mailer: {
          testing: {
            subject: 'A Test Subject',
            just_a_test: 'This is just a test',
            regards: 'Regards, your dev team'
          },
          test_bulk: {
            salutation: 'Hello %{name}'
          }
        }
      }
    }
  end

  class MandrillBatchMailer::TestMailer < MandrillBatchMailer::BaseMailer
    def testing(user)
      @user = user
      mail to: user.email
    end

    def test_bulk(users)
      @user = users.first # TODO: think about I18n.locale
      to_params = users.map do |user|
        [user.email,
          { salutation: I18n.t(:salutation, name: user.first_name,
              scope: 'mandrill.test_mailer.test_bulk') }]
      end.to_h
      mail to: to_params
    end
  end

  let(:test_mailer) { MandrillBatchMailer::TestMailer.new :testing }
  let(:base_mailer) { MandrillBatchMailer::BaseMailer.new :testing }

  before do
    I18n.backend.store_translations :en, translations
  end

  after do
    I18n.backend.reload!
  end

  shared_context 'when intercepting', :intercept do
    before do
      @old_intercept = MandrillBatchMailer.intercept_recipients
      MandrillBatchMailer.intercept_recipients = true
      @old_intercept_mail = MandrillBatchMailer.interception_base_mail
      MandrillBatchMailer.interception_base_mail = 'notifier@some-domain.com'
    end
    after do
      MandrillBatchMailer.intercept_recipients = @old_value
      MandrillBatchMailer.interception_base_mail = @old_intercept_mail
    end
  end

  shared_context 'when not intercepting', intercept: false do
    before do
      @old_intercept = MandrillBatchMailer.intercept_recipients
      MandrillBatchMailer.intercept_recipients = false
    end
    after do
      MandrillBatchMailer.intercept_recipients = @old_intercept
    end
  end

  shared_context 'when delivering', :deliver do
    before do
      @old_deliveries = MandrillBatchMailer.perform_deliveries
      MandrillBatchMailer.perform_deliveries = true
    end
    after do
      MandrillBatchMailer.perform_deliveries = @old_deliveries
    end
  end

  shared_context 'when not delivering', deliver: false do
    before do
      @old_deveries = MandrillBatchMailer.perform_deliveries
      MandrillBatchMailer.perform_deliveries = false
    end
    after do
      MandrillBatchMailer.perform_deliveries = @old_deliveries
    end
  end

  describe '#mail', :intercept do
    subject(:mail) { test_mailer.testing user }
    it { should be_a Hash }

    it 'has the correct template name' do
      expect(mail[:template_name]).to eq 'test-mailer-testing'
    end

    context 'bulky' do
      subject(:mail) { test_mailer.test_bulk more_users }
      it { should be_a Hash }
    end
  end

  describe '#template_name' do
    subject { test_mailer.send :template_name }

    it { should eq 'test-mailer-testing'}

    context 'when calling from BaseMailer' do
      subject { base_mailer.send :template_name }

      it { should eq 'base-mailer-testing' }
    end
  end

  describe '#subject' do
    subject { test_mailer.send :subject }
    context 'when intercepting', :intercept do
      it { should eq '*|subject|*' }
    end
    context 'when not intercepting', intercept: false do
      it { should eq '*|subject|*' }
    end
  end

  describe '#from_name' do
    # TODO: write the test, when mattr is defined
    it 'uses the configured from_name'
  end

  describe '#to' do
    before do
      test_mailer.instance_variable_set :@tos, { user.email => [] }
    end
    subject { test_mailer.send :to }

    context 'when intercepted', :intercept do
      it { should eq [{ email: 'notifier+0@some-domain.com' }] }
    end

    context 'when not intercepted', intercept: false do
      it { should eq [{ email: user.email }] }
    end
  end

  describe '#global_merge_vars' do
    let(:global_merge_vars) { test_mailer.send :global_merge_vars }

    it 'should include the correct translations' do
      expect([
        { name: :subject, content: 'A Test Subject' },
        { name: :just_a_test, content: 'This is just a test' },
        { name: :regards, content: 'Regards, your dev team' },
        { name: :salutation, content: 'Hello' }
      ].to_set).to be_subset global_merge_vars.to_set
    end
  end

  describe '#merge_vars' do
    before do
      test_mailer.instance_variable_set :@tos,
        base_mailer.send(:tos_from, user.email)
    end
    subject(:merge_vars) { test_mailer.send :merge_vars }

    context 'when not intercept', intercept: false do
      it { should eq [{ rcpt: user.email, vars: [] }]}
    end
    context 'when intercept_recipients', :intercept do
      it { expect(merge_vars.first[:rcpt]).to eq 'notifier+0@some-domain.com' }
      it do
        expect(merge_vars.first[:vars].first[:content]).to include user.email
      end
    end
  end

  describe '#tos_from' do
    subject { test_mailer.send :tos_from, input }

    {
      nil => {},
      '' => { '' => {} },
      'some@mail.de' => { 'some@mail.de' => {} },
      [] => {},
      ['some@mail.de', 'some_other@mail.de'] => {
        'some@mail.de' => {}, 'some_other@mail.de' => {} },
      { hello: :world } => { hello: :world }
    }.each do |input, output|
      context "when #{input} given" do
        let(:input) { input }
        it { should eq output }
      end
    end
  end

  describe '#translations' do
    subject { test_mailer.send :translations }
    it do
      should eq translations[:mandrill_batch_mailer][:test_mailer][:testing]
    end
  end

  describe '#shared_translations' do
    subject { test_mailer.send :shared_translations }
    it do
      should eq translations[:mandrill_batch_mailer][:shared_translations]
        .deep_merge(subject)
    end
  end

  describe '#send_template' do
    let(:params) { {} }

    context 'when delivering', :deliver do

      it "calls mandrill's endoint, when performing deliveries" do
        expect(RestClient).to receive(:post)
          .with(MandrillBatchMailer::ENDPOINT, params.to_json)
        test_mailer.send :send_template, params
      end

      context 'when there happens an exception' do
        before do
          allow(RestClient).to receive(:post).and_raise(RestClient::Exception)
        end

        it 'raises exception' do
          expect { test_mailer.send :send_template, params }.to raise_exception
        end
      end
    end

    context 'when not performing deliveries', deliver: false do
      after { test_mailer.send :send_template, params }
      it 'just logs something' do
        expect(MandrillBatchMailer.logger).to receive(:info)
      end
    end
  end
end
