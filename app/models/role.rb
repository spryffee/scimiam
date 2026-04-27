class Role < ApplicationRecord

  has_many :accesses, dependent: :restrict_with_error
  has_many :users, through: :accesses
  belongs_to :approval_workflow, optional: true

  validates :name, presence: true
  validates :name, uniqueness: true

  def self.ransackable_attributes(auth_object = nil)
    %w[name is_active approval_workflow_id]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[accesses approval_workflow]
  end

end