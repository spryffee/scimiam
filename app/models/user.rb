class User < ActiveRecord::Base

  has_many :accesses
  has_many :roles, through: :accesses

  READWRITE_ATTRS = %w{
    scim_uid
    username
    displayname
    work_email_address
    groups
  }

  # has_and_belongs_to_many :groups

  validates :username, presence: true
  validates :username, uniqueness: true

  def self.scim_resource_type
    return Scimitar::Resources::User
  end

  def self.scim_attributes_map
    return {
      id:           :id,
      externalId:   :scim_uid,
      userName:     :username,
      displayName:  :displayname,
      name:       {
        givenName:  :first_name,
        familyName: :last_name
      },
      emails: [
        {
          match: 'type',
          with:  'work',
          using: {
            value:   :work_email_address,
            primary: true
          }
        }
      ],
      roles: [
        {
          list:  :roles,
          using: {
            value:   :id,
            display: :displayname
          }
        }
      ],
      active: :is_active
    }
  end

  def self.scim_mutable_attributes
    return nil
  end

  def self.scim_queryable_attributes
    return {
      'id'                => { column: :primary_key },
      'externalId'        => { column: :scim_uid },
      'meta.lastModified' => { column: :updated_at },
      'displayName'       => { column: :displayname },
      'givenName'         => { column: :first_name },
      'familyName'        => { column: :last_name }
    }
  end

  def self.scim_timestamps_map
    {
      created:      :created_at,
      lastModified: :updated_at
    }
  end

  def self.ransackable_attributes(auth_object = nil)
    %w[username displayname work_email_address is_active]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[roles]
  end

  include Scimitar::Resources::Mixin
end