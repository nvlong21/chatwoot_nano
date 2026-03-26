module Enterprise::Account::PlanUsageAndLimits # rubocop:disable Metrics/ModuleLength
  def usage_limits
    {
      agents: agent_limits.to_i,
      inboxes: get_limits(:inboxes).to_i
    }
  end

  def email_transcript_enabled?
    default_plan = InstallationConfig.find_by(name: 'CHATWOOT_CLOUD_PLANS')&.value&.first
    return true if default_plan.blank?

    plan_name.present? && plan_name != default_plan['name']
  end

  def email_rate_limit
    account_limit || plan_email_limit || global_limit || default_limit
  end

  def subscribed_features
    plan_features = InstallationConfig.find_by(name: 'CHATWOOT_CLOUD_PLAN_FEATURES')&.value
    return [] if plan_features.blank?

    plan_features[plan_name]
  end

  private

  def plan_email_limit
    config = InstallationConfig.find_by(name: 'ACCOUNT_EMAILS_PLAN_LIMITS')&.value
    return nil if config.blank? || plan_name.blank?

    parsed = config.is_a?(String) ? JSON.parse(config) : config
    parsed[plan_name.downcase]&.to_i
  rescue StandardError
    nil
  end

  def plan_name
    custom_attributes['plan_name']
  end

  def agent_limits
    subscribed_quantity = custom_attributes['subscribed_quantity']
    subscribed_quantity || get_limits(:agents)
  end

  def get_limits(limit_name)
    config_name = "ACCOUNT_#{limit_name.to_s.upcase}_LIMIT"
    return self[:limits][limit_name.to_s] if self[:limits][limit_name.to_s].present?

    return GlobalConfig.get(config_name)[config_name] if GlobalConfig.get(config_name)[config_name].present?

    ChatwootApp.max_limit
  end

  def validate_limit_keys
    errors.add(:limits, ': Invalid data') unless self[:limits].is_a? Hash
    self[:limits] = {} if self[:limits].blank?

    limit_schema = {
      'type' => 'object',
      'properties' => {
        'inboxes' => { 'type': 'number' },
        'agents' => { 'type': 'number' },
        'emails' => { 'type': 'number' }
      },
      'required' => [],
      'additionalProperties' => false
    }

    errors.add(:limits, ': Invalid data') unless JSONSchemer.schema(limit_schema).valid?(self[:limits])
  end
end
