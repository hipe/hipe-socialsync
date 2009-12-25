require 'dm-core'
require 'dm-validations'
require 'md5'
require 'hipe-core/infrastructure/erroneous'

repository(:default).adapter.resource_naming_convention = lambda do |value|
  /[^:]+$/.match(value)[0].gsub(/([a-z])([A-Z])/,'\1_\2').downcase + 's'
end

module Hipe::SocialSync::Model

  class ValidationError
    attr_accessor :details    
    def initialize(msg,details)
      @msg = msg
      @details = details
    end
  end
  
  class ValidationErrors
    include Hipe::Erroneous
    def self.[](*args)
      if (String===args[0] && (args.size==0 or args.size==1 && Hash===args[1]))
        ret = self.new
        ret.errors << ValidationError.new(args[0],args[1])
      elsif (1==args.size and Common===args[0])
        raise ArgumentError.new("object must be invalid") if args[0].valid? 
        errors = args[0].errors
        ret = self.new        
        errors.keys.each do |key|
          ret.errors << ValidationError.new(errors[key], :field_name => key)          
        end
      else
        raise ArgumentError.new("bad signature")
      end
      ret
    end
  end

  module Inflector
    def self.humanize(str) #@TODO see if this is the same as Extlib::Inflector.humanize
      str.to_s.match(/[^:]+$/)[0].gsub(/([a-z])([A-Z])/,'\1 \2').downcase
    end    
    def self.class_basename(cls)
      cls.match(/([^:]*)$/).captures[0]      
    end
  end
  
  module Common
    include DataMapper::Types
    def self.included(model)
      model.extend ClassMethods
      model.property :id, Serial
    end
  end

  module ClassMethods
    def human_name
      Inflector.humanize(self.to_s)
    end    
    def class_basename
      Inflector.class_basename(self.to_s)
    end    
    def soft(obj)
      Hipe::SocialSync::SoftException[{:object => obj}]
    end
    def create_or_throw *args
      debugger
      obj = self.new(args[0])
      throw :invalid, ValidationErrors[obj] unless obj.valid?
      obj.save
    end
    def first_or_throw *args
      ret = nil
      return ret if ret = first(*args)
      msg = %{Can't find #{human_name} with } + # makes some assumptions about how args look!
        ( args[0].map{|pair|  %{#{Inflector.humanize(pair[0])} #{pair[1].inspect}}} * ' and ' ) + '.'
      throw :invalid, ValidationErrors[msg]
    end  
    def to_time_or_throw(mixed)
      return mixed if DateTime === mixed
      begin                                                                                
        datetime = DateTime.parse(mixed)                                                   
        return datetime                                                                    
      rescue ArgumentError => e                                                              
        throw :invalid, ValidationErrors[%{#{e.message}: #{mixed.inspect}}, {:original_exception=>e}]
      end                                                                                  
    end 
    def kind_of_or_throw(name, value, *klasses)
      klasses.each { |k| return if value.kind_of?(k) }
      should_be = klasses.map{|k| k.respond_to?(:class_basename) ? k.class_basename : k.name } * ' or '
      msg = if (value.nil?)
        %{#{name} not found.}.capitalize
      else
        %{#{name} should be #{should_be} but was #{Inflector.class_basename(value)}}
      end      
      throw :invalid, ValidationErrors[msg]
    end                                                                                  
  end

  class Relationship
    include DataMapper::Resource
    include Common    
    property :type, String, :length => (4..40)
    property :left_class, String, :length => (2..50)
    property :left_id, Integer, :required => true
    property :right_class, String, :length => (2..50)
    property :right_id, Integer, :required => true
    

    def self.kreate left, type, right
      kind_of_or_throw :left, left, Common
      kind_of_or_throw :left, right, Common      
      kind_of_or_throw :type, type, Symbol
      
      obj = self.new  :left_class  => left.class.to_s,  :right_class => right.class.to_s,
                      :left_id     => left.id,          :right_id    => right.id,
                      :type        => type.to_s
      throw :invalid, ValidationErrors[obj] unless obj.valid? 
      obj.save
    end
  end

  class Event
    include DataMapper::Resource
    include Common    
    property :type, String, :length => (2..20)
    property :happened_at, DateTime, :required => true

    # details should be a hash of zero or more objects whose keys represent the named roles
    def self.kreate event_type, details
      obj = self.new :type => event_type.to_s, :happened_at => DateTime.now
      throw :invalid, ValidationErrors[obj] unless obj.valid?
      obj.save
      details.each do |role, obj2|
        kind_of_or_throw role, obj2, ::Object
        Relationship.kreate obj, role, obj2
      end
    end
  end

  class User
    include DataMapper::Resource
    include Common    

    property :email, String, :length=>(1..80), :format => :email_address, :unique => true,
      :messages => {
        :format    => lambda{|res, prop| '"%s" is not a valid email address.'.t(prop)  },
        :is_unique => lambda{|res, prop| 'There is already a service "%s".'.t(res.send(prop.name))}    
      } 
    property :encrypted_password, String          
    # validates_format :email, :format=> :email_address, :message => 'blahblah' #@TODO uncomment & see bug
    #has n, :accounts
    
    def self.kreate email, admin
      email.strip!
      kind_of_or_throw :admin, admin, User
      obj = self.create_or_throw(:email => email)
      debugger
      obj.save
      Event.kreate :user_created, :user => obj, :by => admin
      obj
    end    
    
    def self.remove(target_user_email, current_user_email)      
      ret = catch(:invalid)
      current_user = User.first_or_throw(:email => current_user_email)
      target_user = User.first_or_throw(:email => target_user_email)    
      Event.kreate :user_deleted, :user => target_user, :by => current_user
      target_user.destroy!
      %{Deleted user "#{target_user.email}" (##{id}).}
    end
  end

 #class Service
 #  include DataMapper::Resource
 #  include Common
 #  
 #  property :name, String, :length=>(2..20)
 #  has n, :accounts
 #  validates_is_unique :name, 
 #    :message => lambda{|res,prop| 'There is already a service "%s".'.t(res.send(prop.name))}    
 #  
 #  #def self.kreate name, user_obj
 #  #  kind_of_or_throw :user, user_obj, User
 #  #  obj = self.create(:name=>name)
 #  #  raise soft(obj) unless obj.valid?
 #  #  Event.kreate :service_created, :service=>obj, :by=>user
 #  #  obj
 #  #end
 #  #
 #  #def self.remove(target_name, current_user_email)      
 #  #  current_user = User.first_or_throw(:email => current_user_email)
 #  #  target = Service.first_or_throw(:name => target_name)      
 #  #  Event.kreate :service_deleted, :service => target, :by => current_user
 #  #  id = target.id; target.destroy!
 #  #  %{Deleted service "#{target_name}" (##{id}).}
 #  #end    
 #  
 #end
 #
 #class Account
 #  include DataMapper::Resource
 #  include Common
 #  
 #  belongs_to :user
 #  belongs_to :service
 #  property :name_credential, String, :length => (0..20)
 #  def self.kreate(service_name, name_credential, user_name)
 #    user_obj = User.first_or_throw(:email=>user_name)
 #    service_obj = Service.first_or_throw(:name=>service_name)
 #    obj = self.create(:user => user_obj, :service => service_obj, :name_credential => name_credential)
 #    raise soft(obj) unless obj.valid?
 #    Event.kreate :account_added, :account => obj, :by => user_obj      
 #    obj
 #  end
 #end
 #
 #class Item
 #  include DataMapper::Resource
 #  include Common
 #  
 #  belongs_to :account
 #  property :foreign_id, Integer, :required => true
 #  property :author, String, :length => (2..20)
 #  property :content, Text, :required => true
 #  property :content_md5, String, :length => (32)
 #  property :keywords, Text
 #  property :published_at, DateTime, :required => true
 #  property :status, String
 #  property :title, String, :length => (1..80)
 #  validates_is_unique :content_md5, :scope => :account_id, 
 #    :message => lambda{|res,prop| %{md5 "%s" is already taken}.t(res.send(prop.name))}
 #  validates_is_unique :content, :scope => :account_id, 
 #    :message => lambda { |res,prop| 
 #      %{Another blog entry (#%s) from %s already has that content}.t(
 #        res.foreign_id, res.published_at.strftime('%Y-%m-%d')
 #      )
 #    }
 #
 #  
 #  def self.kreate(account_obj, foreign_id, author_str, content, keywords_str, published_at, status, title, curr_user_o)
 #    published_at = to_time_or_throw published_at      
 #    kind_of_or_throw :user, current_user_obj, User
 #    kind_of_or_throw 'date/time', published_at, DateTime
 #    kind_of_or_throw :account, account_obj, Account
 #    kind_of_or_throw :keywords, keywords, String
 #    md5 = MD5.new(content).to_s  
 #    unique! md5, :content_md5    
 #    obj = self.create(
 #      :account        => account_obj,         
 #      :foreign_id     => foreign_id,
 #      :author         => author_str,
 #      :content        => content_str,
 #      :content_md5    => md5,
 #      :keywords       => keywords,
 #      :published_at   => published_at,
 #      :status         => status,
 #      :title          => title
 #    )
 #    raise soft(obj) unless obj.valid?
 #    Event.kreate(:item_imported, :item=>obj, :account=>account_obj, :by => current_user_obj)
 #    obj
 #  end
 #end
 #
 #class UploadedFile
 #  include DataMapper::Resource
 #  include Common    
 #end
 #

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
    User.create_or_throw(:email=>'admin')
  end  
  #
  #unless repo.storage_exists?('services')
  #  Service.auto_migrate!
  #  #Service.create(:name => 'wordpress')
  #end
  #
  #unless repo.storage_exists?('accounts')
  #  Account.auto_migrate!
  #end  
  #
  #unless repo.storage_exists?('items')
  #  Item.auto_migrate!
  #end
end # module Hipe::SocialSync
