require 'rails_helper'
require Rails.root.join 'spec/models/concerns/reauthorizable_shared.rb'

RSpec.describe Integrations::Hook do
  it_behaves_like 'reauthorizable'

  context 'with validations' do
    it { is_expected.to validate_presence_of(:app_id) }
    it { is_expected.to validate_presence_of(:account_id) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:account) }
  end

  describe 'when trying to create multiple hooks for an app' do
    let(:account) { create(:account) }

    context 'when app allows multiple hooks' do
      it 'allows to create succesfully' do
        create(:integrations_hook, account: account, app_id: 'webhook')
        expect(build(:integrations_hook, account: account, app_id: 'webhook').valid?).to be true
      end
    end

    context 'when app doesnot allow multiple hooks' do
      it 'throws invalid error' do
        create(:integrations_hook, account: account, app_id: 'slack')
        expect(build(:integrations_hook, account: account, app_id: 'slack').valid?).to be false
      end
    end
  end

  describe 'scopes' do
    let(:account) { create(:account) }
    let(:inbox) { create(:inbox, account: account) }
    let!(:account_hook) { create(:integrations_hook, account: account, app_id: 'webhook') }
    let!(:inbox_hook) do
      create(:integrations_hook,
             account: account,
             app_id: 'google_translate',
             inbox: inbox,
             settings: {
               project_id: 'test-project',
               credentials: { type: 'service_account' }
             })
    end

    it 'returns account hooks' do
      expect(described_class.account_hooks.pluck(:id)).to include(account_hook.id)
      expect(described_class.account_hooks.pluck(:id)).not_to include(inbox_hook.id)
    end

    it 'returns inbox hooks' do
      expect(described_class.inbox_hooks.pluck(:id)).to include(inbox_hook.id)
      expect(described_class.inbox_hooks.pluck(:id)).not_to include(account_hook.id)
    end
  end

end
