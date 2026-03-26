import { getters } from '../../campaigns';
import campaigns from './fixtures';

describe('#getters', () => {
  it('get one_off campaigns', () => {
    const state = { records: campaigns };
    expect(getters.getCampaigns(state)('one_off')).toEqual([
      campaigns[0],
      campaigns[1],
      campaigns[2],
    ]);
  });

  it('get campaigns by channel type', () => {
    const state = { records: campaigns };
    expect(
      getters.getCampaigns(state)('one_off', ['Channel::Whatsapp'])
    ).toEqual([campaigns[1]]);
  });

  it('get campaigns by multiple channel types', () => {
    const state = { records: campaigns };
    expect(
      getters.getCampaigns(state)('one_off', [
        'Channel::TwilioSms',
        'Channel::Sms',
      ])
    ).toEqual([campaigns[0], campaigns[2]]);
  });

  it('get SMS campaigns', () => {
    const state = { records: campaigns };
    const mockGetters = {
      getCampaigns: getters.getCampaigns(state),
    };
    expect(getters.getSMSCampaigns(state, mockGetters)).toEqual([
      campaigns[0],
      campaigns[2],
    ]);
  });

  it('get WhatsApp campaigns', () => {
    const state = { records: campaigns };
    const mockGetters = {
      getCampaigns: getters.getCampaigns(state),
    };
    expect(getters.getWhatsAppCampaigns(state, mockGetters)).toEqual([
      campaigns[1],
    ]);
  });

  it('get all campaigns', () => {
    const state = { records: campaigns };
    expect(getters.getAllCampaigns(state)).toEqual(campaigns);
  });

  it('getUIFlags', () => {
    const state = {
      uiFlags: {
        isFetching: true,
        isCreating: false,
      },
    };
    expect(getters.getUIFlags(state)).toEqual({
      isFetching: true,
      isCreating: false,
    });
  });
});
