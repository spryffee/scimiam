module Provisioning
  class BaseStrategy
    attr_reader :role

    def initialize(role)
      @role = role
    end

    def sync
      raise NotImplementedError, "#{self.class} must implement #sync"
    end

    protected

    def approved_user_emails
      @approved_user_emails ||= role.accesses
                                   .includes(:user)
                                   .where(approved: true)
                                   .map { |access| access.user.work_email_address }
                                   .compact
    end
  end
end