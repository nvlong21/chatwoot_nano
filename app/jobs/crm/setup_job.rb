class Crm::SetupJob < ApplicationJob
  queue_as :default

  def perform(hook_id)
    hook = Integrations::Hook.find_by(id: hook_id)

    return if hook.blank? || hook.disabled?

    Rails.logger.error "Unsupported CRM app_id: #{hook.app_id}"
  end
end
