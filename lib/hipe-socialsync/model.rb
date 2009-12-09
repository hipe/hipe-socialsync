require 'dm-core'
require 'dm-aggregates'

DataMapper.setup(:default, %{sqlite3://#{Hipe::SocialSync::DIR}/data/teh-data.db})

repository(:default).adapter.resource_naming_convention = lambda do |value|
  /[^:]+$/.match(value)[0].gsub(/([a-z])([A-Z])/,'\1_\2').downcase + 's'
end

module Hipe::SocialSync::Model

  class Base; end

  Excepto = Hipe::SocialSync::Exception

  module BaseClassMethods
    include DataMapper::Types
    def self.extended(mod)
      mod.property :id, Serial      
    end
  end

  class Relationship < Base
    include DataMapper::Resource
    extend BaseClassMethods
    def self.kreate left, type, right
      obj = self.new  :left_class  => left.class.to_s,  :right_class => right.class.to_s,
                      :left_id     => left.id,          :right_id    => right.id,
                      :type        => type.to_s
      obj.save
    end
    property :id, Serial      
    property :type, String
    property :left_class, String
    property :left_id, Integer
    property :right_class, String
    property :right_id, Integer
  end

  class Event < Base
    include DataMapper::Resource
    extend BaseClassMethods    
    # details should be a hash of zero or more objects whose keys represent the named roles
    def self.kreate event_type, details
      raise Excepto.factory("must be non zero length string") unless event_type.to_s.length > 0
      obj = self.new :type => event_type.to_s, :happened_at => DateTime.now
      obj.save
      details.each do |role,obj2|
        Relationship.kreate obj, role.to_s, obj2
      end
    end
    property :type, String
    property :happened_at, DateTime
  end

  class User < Base
    include DataMapper::Resource
    extend BaseClassMethods
    def self.kreate email, admin
      email.strip!
      existing = self.first(:email => email)
      raies Excepto.factory(%{need an admin}) unless admin.instance_of? User
      raise Excepto.factory(%{user "#{email}" already exists}) if existing
      obj = self.create :email => email
      Event.kreate :user_created, :user => obj, :by => admin
    end
    property :email,                String
    property :encrypted_password,   String
  end
  
  class Service < Base
    include DataMapper::Resource
    extend BaseClassMethods    
    property :name, String
    def self.kreate name, user
      existing = self.first(:name=>name)
      raise Excepto.factory("who is the user adding this service?") unless user.instance_of? User
      raise Excepto.factory(%{Service "#{name}" already exists.}) if existing
      obj = self.create(:name=>name)
      Event.kreate :service_created, :service=>obj, :by=>user
    end
  end

  class Item < Base
    include DataMapper::Resource
    extend BaseClassMethods    
    belongs_to :service
    property :author, String
    property :published_at, DateTime
    property :content_md5, String
    property :content, Text
  end

  class UploadedFile < Base
    include DataMapper::Resource
    extend BaseClassMethods
  end

  repo = DataMapper.repository

  
  unless repo.storage_exists?('relationships')
    Relationship.auto_migrate!
  end
  
  unless repo.storage_exists?('events')
    Event.auto_migrate!
  end

  unless repo.storage_exists?('users')
    User.auto_migrate!
    User.create(:email=>'admin').save
  end
 
  unless repo.storage_exists?('services')
    Service.auto_migrate!
  end

end # module Hipe::SocialSync





# DB = Sequel.sqlite('mine.db')

# require 'sequel'
# Sequel::Model.plugin(:schema)

# class Service < Sequel::Model
#
#   set_schema do
#     primary_key :id
#
#     varchar :name, :unique => true, :empty => false
#     boolean :checked  , :default => false
#   end
#
#   create_table unless table_exists?
#
#   if empty?
#     create :name => 'tumblr'
#     create :name => 'wordpress'
#   end
#
# end
