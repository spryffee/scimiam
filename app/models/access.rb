class Access < ActiveRecord::Base
  belongs_to :user
  belongs_to :role

  validates :user_id, uniqueness: { scope: :role_id }
  validates :role_id, :user_id, presence: true
  validate :role_has_approval_workflow, on: :create
  
  enum status: {
    pending: 'pending',
    pending_secondary: 'pending_secondary',
    approved: 'approved'
  }

  # after_create :initialize_approval_workflow

  # attr_accessor :performed_by

  def approve!(approver_id)
    return false unless can_approve?(approver_id)
    
    self.approvals = approvals + [approver_id]
    update_status!
    if save
      approver = User.find(approver_id)
      AuditLog.create(event: "Access role #{role.name} approved for #{user.displayname} by #{approver.displayname}")
    end
    true
  end

  def can_approve?(approver_id)
    return false unless role.approval_workflow
    return false if approved?
    return false if approvals.include?(approver_id)

    workflow = role.approval_workflow

    case status
    when 'pending'
      workflow.primary_approver_ids.include?(approver_id)
    when 'pending_secondary'
      workflow.secondary_approver_ids.include?(approver_id)
    else
      false
    end
  end

  def pending_approvers
    return [] unless role.approval_workflow
    
    case status
    when 'pending'
      role.approval_workflow.primary_approver_ids - approvals
    when 'pending_secondary'
      role.approval_workflow.secondary_approver_ids - approvals
    else
      []
    end
  end

  private

  def role_has_approval_workflow
    unless role&.approval_workflow
      errors.add(:role, "must have an approval workflow")
    end
  end

  # def initialize_approval_workflow
  #   self.status = 'pending'
  #   self.approvals = []
  #   save
  # end

  def update_status!
    workflow = role.approval_workflow
    
    case status
    when 'pending'
      if approvals.size >= workflow.required_primary_approvals
        self.status = workflow.required_secondary_approvals.positive? ? 'pending_secondary' : 'approved'
        self.approved = true if status == 'approved'
      end
    when 'pending_secondary'
      if approvals.size >= (workflow.required_primary_approvals + workflow.required_secondary_approvals)
        self.status = 'approved'
        self.approved = true
      end
    end
  end

  def self.ransackable_attributes(auth_object = nil)
    %w[user_id role_id status]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[user role]
  end

  # def log_access_event
  #   if destroyed?
  #     performer = User.find(approvals.last) if approvals.present?
  #     performer_name = performer&.displayname || 'System'
      
  #     event = if status == 'pending'
  #       "Access role #{role.name} declined for #{user.displayname} by #{performer_name}"
  #     else
  #       "Access role #{role.name} revoked for #{user.displayname} by #{performer_name}"
  #     end
      
  #     AuditLog.create(event: event)
  #   end
  # end
end 