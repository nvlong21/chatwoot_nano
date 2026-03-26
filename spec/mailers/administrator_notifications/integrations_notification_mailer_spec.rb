require 'rails_helper'
require Rails.root.join 'spec/mailers/administrator_notifications/shared/smtp_config_shared.rb'

RSpec.describe AdministratorNotifications::IntegrationsNotificationMailer do
  include_context 'with smtp config'

  let!(:account) { create(:account) }
  let!(:administrator) { create(:user, :administrator, email: 'admin@example.com', account: account) }
  let!(:another_administrator) { create(:user, :administrator, email: 'owner@example.com', account: account) }

  describe 'slack_disconnect' do
    let(:mail) { described_class.with(account: account).slack_disconnect.deliver_now }

    it 'renders the subject' do
      expect(mail.subject).to eq('Your Slack integration has expired')
    end

    it 'renders the receiver email' do
      expect(mail.to).to contain_exactly(administrator.email, another_administrator.email)
    end

    it 'includes reconnect instructions in the body' do
      expect(mail.body.encoded).to include('To continue receiving messages on Slack, please delete the integration and connect your workspace again')
    end
  end

end
