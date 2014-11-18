class PartnerConnection < ActiveRecord::Base
  UnknownAuthMechanismError = Class.new(StandardError)

  belongs_to :partner, :counter_cache => true
  belongs_to :imap_provider, :counter_cache => true
  has_many :users, :dependent => :destroy

  validates_presence_of :imap_provider_id
  validates_uniqueness_of :imap_provider_id, :scope => :partner_id

  # Public: Used by ActiveAdmin.
  def display_name
    self.auth_mechanism
  end

  # Public: Return a collection of users that corresponds to the
  # connection type. For example, 'ImapProvider::Plain' gives a
  # collection of 'User::Plain' records.
  def users
    user_type = self.imap_provider.type.gsub("ImapProvider::", "User::")
    user_type = user_type.constantize
    user_type.where(:partner_connection_id => self.id, :type => user_type)
  end

  def auth_mechanism
    self.imap_provider.auth_mechanism
  end

  # Public: Create a partner connection using the specified auth mechanism.
  def self.for_auth_mechanism(auth_mechanism)
    conn_type = ImapProvider.find_by_auth_mechanism(auth_mechanism)
    raise UnknownAuthMechanismError.new("Unknown auth mechanism: #{auth_mechanism}") if conn_type.nil?
    clazz = self.imap_provider.type.gsub("ImapProvider::", "PartnerConnection::").constantize
    scoping do
      clazz.create(*args, &block)
    end
  end

  # Public: Narrow down a collection of PartnerConnection objects by
  # the auth_mechanism.
  def self.where_auth_mechanism(auth_mechanism)
    conn_type = ImapProvider.find_by_auth_mechanism(auth_mechanism)
    raise UnknownAuthMechanismError.new("Unknown auth mechanism: #{auth_mechanism}") if conn_type.nil?
    if conn_type
      where(:imap_provider_id => conn_type.id)
    else
      where("true = false")
    end
  end

  def self.connection_fields
    []
  end

  def connection_fields
    self.class.connection_fields
  end
end
