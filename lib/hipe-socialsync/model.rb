require 'dm-validations'
require 'md5'

repository(:default).adapter.resource_naming_convention = lambda do |value|
  /[^:]+$/.match(value)[0].gsub(/([a-z])([A-Z])/,'\1_\2').downcase + 's'
end

module Hipe::SocialSync::Model

  module Common
    include DataMapper::Types
    include Extlib::Assertions    
    def self.included(model)
      model.extend ClassMethods
      model.property :id, Serial
    end
    def self.humanize(str)
      str.to_s.match(/[^:]+$/)[0].gsub(/([a-z])([A-Z])/,'\1 \2').downcase
    end
  end

  module ClassMethods
    def validates_is_uneek(*fields)
      opts = opts_from_validator_args(fields)
      add_validator_to_context(opts, fields, UneeknessValidator)
    end
    def human_name
      Common.humanize(self.to_s)
    end    
    def soft(obj)
      Hipe::SocialSync::SoftException[{:object => obj}]
    end
    def first! *args
      ret = nil
      return ret if ret = first(*args)
      # make some assumptions about how args look!
      msg = %{Can't find #{human_name} with } + 
        ( args[0].map{|pair|  %{#{Common.humanize(pair[0])} #{pair[1].inspect}}} * ' and ' ) + '.'
      raise Hipe::SocialSync::SoftException[msg]
    end  
    def to_time!(mixed)
      return mixed if DateTime === mixed
      begin                                                                                
        datetime = DateTime.parse(mixed)                                                   
        return datetime                                                                    
      rescue ArgumentError => e                                                              
        raise Exception[%{#{e.message}: #{mixed.inspect}},{:original_exception=>e}]        
      end                                                                                  
    end                                                                                    
  end

  # Rewrite of the builtin that allows custom messages that include the value of the field 
  #
  class UneeknessValidator < DataMapper::Validate::GenericValidator
    def call(target)
      value = target.send(field_name)
      opts = { :fields => target.model.key, field_name => value }
      Array(@options[:scope]).each { |subject| opts[subject] = target.send(subject) }
      resource = DataMapper.repository(target.repository.name) { target.model.first(opts) }
      return true if resource.nil?
      return true if target.saved? && resource.key == target.key
      # message = @options[:message] || DataMapper::Validate::ValidationErrors.default_error_message(:taken, field_name)
      message = if @options[:message]
        @options[:message].respond_to?(:call) ? @options[:message].call(resource) : @options[:message]
      else
        %{#{target.class.human_name.capitalize} "%value%" already exists.}
      end
      message = message.gsub(/%value%/){ |x| value }  
      add_error(target, message, field_name)
      false
    end
  end

  class Relationship
    include DataMapper::Resource
    include Common    
    property :type, String, :length => (4..40)
    property :left_class, String, :length => (2..50)
    property :left_id, Integer
    property :right_class, String, :length => (2..50)
    property :right_id, Integer
    

    def self.kreate left, type, right
      assert_kind_of :left, left, Common
      assert_kind_of :left, right, Common      
      assert_kind_of :type, type, Symbol
      
      obj = self.new  :left_class  => left.class.to_s,  :right_class => right.class.to_s,
                      :left_id     => left.id,          :right_id    => right.id,
                      :type        => type.to_s
      obj.save
    end
  end

  class Event
    include DataMapper::Resource
    include Common    

    # details should be a hash of zero or more objects whose keys represent the named roles
    def self.kreate event_type, details
      raise Exception[("must be non zero length string")] unless event_type.to_s.length > 0
      obj = self.new :type => event_type.to_s, :happened_at => DateTime.now
      obj.save
      details.each do |role, obj2|
        assert_kind_of role, obj2, ::Object
        Relationship.kreate obj, role, obj2
      end
    end
    property :type, String
    property :happened_at, DateTime
  end

  class User
    include DataMapper::Resource
    include Common
    
    property :email, String, :length=>(1..80), :format=>:email_address, 
      :message => lambda { |field, value| '"%s" is not a valid email address.'.t(value) }
    property :encrypted_password, String
    has n, :accounts
    validates_is_uneek :email
    
    def self.kreate email, admin
      email.strip!
      assert_kind_of :admin, admin, User
      obj = self.create :email => email
      raise soft(obj) unless obj.valid? 
      Event.kreate :user_created, :user => obj, :by => admin
      obj
    end    
    
    def self.remove(target_user_email, current_user_email)      
      current_user = User.first!(:email => current_user_email)
      target_user = User.first!(:email => target_user_email)    
      Event.kreate :user_deleted, :user => target_user, :by => current_user
      target_user.destroy!
      %{Deleted user "#{target_user.email}" (##{id}).}
    end
  end

  class Service
    include DataMapper::Resource
    include Common
    
    property :name, String, :length=>(2..20)
    has n, :accounts
    validates_is_uneek :name
    
    def self.kreate name, user_obj
      assert_kind_of :user, user_obj, User
      obj = self.create(:name=>name)
      raise soft(obj) unless obj.valid?
      Event.kreate :service_created, :service=>obj, :by=>user
      obj
    end
    
    def self.remove(target_name, current_user_email)      
      current_user = User.first!(:email => current_user_email)
      target = Service.first!(:name => target_name)      
      Event.kreate :service_deleted, :service => target, :by => current_user
      id = target.id; target.destroy!
      %{Deleted service "#{target_name}" (##{id}).}
    end    
    
  end
  
  class Account
    include DataMapper::Resource
    include Common
    
    belongs_to :user
    belongs_to :service
    property :name_credential, String, :length => (0..20)
    def self.kreate(service_name, name_credential, user_name)
      user_obj = User.first!(:email=>user_name)
      service_obj = Service.first!(:name=>service_name)
      obj = self.create(:user => user_obj, :service => service_obj, :name_credential => name_credential)
      raise soft(obj) unless obj.valid?
      Event.kreate :account_added, :account => obj, :by => user_obj      
      obj
    end
  end

  class Item
    include DataMapper::Resource
    include Common
    
    belongs_to :account
    property :foreign_id, Integer, :required => true
    property :author, String, :length => (2..20)
    property :content, Text, :required => true
    property :content_md5, String, :length => (32)
    property :keywords, Text
    property :published_at, DateTime, :required => true
    property :status, String
    property :title, String, :length => (1..80)
    validates_is_uneek :content_md5, :scope => :account_id, :message => %{md5 "%value%" is already taken}
    validates_is_uneek :content,     :scope => :account_id, :message => 
      lambda{|item| %{There is another article from "#{item.publised_at}" with that same content} }

    
    def self.kreate(account_obj, foreign_id, author_str, content, keywords_str, published_at, status, title, curr_user_o)
      published_at = to_time! published_at      
      assert_kind_of :user, current_user_obj, User
      assert_kind_of 'date/time', published_at, DateTime
      assert_kind_of :account, account_obj, Account
      assert_kind_of :keywords, keywords, String
      md5 = MD5.new(content).to_s  
      unique! md5, :content_md5    
      obj = self.create(
        :account        => account_obj,         
        :foreign_id     => foreign_id,
        :author         => author_str,
        :content        => content_str,
        :content_md5    => md5,
        :keywords       => keywords,
        :published_at   => published_at,
        :status         => status,
        :title          => title
      )
      raise soft(obj) unless obj.valid?
      Event.kreate(:item_imported, :item=>obj, :account=>account_obj, :by => current_user_obj)
      obj
    end
  end

  class UploadedFile
    include DataMapper::Resource
    include Common    
  end


  ################## build the database ############################

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
    Service.create(:name => 'wordpress').save
    Service.create(:name => 'tumblr').save
  end
  
  unless repo.storage_exists?('accounts')
    Account.auto_migrate!
  end  
  
  unless repo.storage_exists?('items')
    Item.auto_migrate!
  end
end # module Hipe::SocialSync

# def class_basename(cls)
#   cls.to_s.match(/([^:]*)$/).captures[0]
# end
