require 'dm-core'
DataMapper.setup(:default, 'sqlite3:data/teh-data.db')

module Hipe::SocialSync
  
  class Base
    include DataMapper::Resource
    property :id, Serial
  end
  
  class Relationship < Base
    def self.kreate left, type, right
      obj = self.new  :left_class  => left.class.to_s,  :right_class => right.class.to_s,
                      :left_id     => left.id,          :right_id    => right.id,
                      :type        => type.to_s
      obj.save
    end
    property :type, String
    property :left_class, String
    property :left_id, Integer
    property :right_class, String
    property :right_id, Integer
  end
  
  class Event < Base
    # details should be a hash of zero or more objects whose keys represent the named roles
    def self.kreate type, details
      raise HipeException.factory("must be non zero length string") unless event_type.to_s.length > 0
      obj = self.new :type => type.to_s, :happened_at => DateTime.now
      obj.save
      details.each do |role,obj2|
        Relationship.kreate obj, :role, obj2
      end
    end
    property :type, String
    property :happened_at, DateTime
  end  
  
  class User < Base
    def self.kreate email
      existing = self[:email => email.strip!]
      raise HipeException.factory(%{user "#{email}" already exists}) if existing
      obj = self.create :email => email
      Event.kreate :user_created, :user => obj
    end    
    property :email,                String
    property :encrypted_password,   String
  end  
  
  class Service < Base
    property :name, String
  end
  
  class Item < Base
    belongs_to :service
    property :author, String
    property :published_at, DateTime
    property :content_md5, String
    property :content, Text    
  end
  
  class UploadedFile < Base
    
  end

  repo = DataMapper.repository


  unless repo.storage_exists?('relationship')
    Service.auto_migrate!  
  end
  
  unless repo.storage_exists?('event')
    User.auto_migrate!
  end

  unless repo.storage_exists?('user')
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
