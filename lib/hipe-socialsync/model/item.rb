module Hipe::SocialSync::Model
  class Item
    include DataMapper::Resource
    include DataObjectCommon
    include Hipe::AsciiTypesetting::Methods

    belongs_to :account, :model => 'Account'
    has 1, :user, :through => :account
    has 1, :service, :through => :account
    belongs_to :source, :model => 'Item', :required => false
    has n, :targets, :model => 'Item', :child_key => [:source_id]
    has n, :target_accounts, :model => 'ItemAccountTargeting'
    property :foreign_id, Integer, :required => true
    property :author, String, :length => (2..40)
    property :content, Text, :required => true
    property :content_md5, String, :length => (32)
    property :keywords, Text
    property :published_at, DateTime, :required => true
    # property :sync_group_id, Integer, :required => false
    property :status, String
    property :title, String, :length => (1..80)
    validates_is_unique :content_md5, :scope => :account_id,
      :message => lambda{|res,prop| %{Md5 "%s" is already taken.}.t(res.send(prop.name))}
    validates_is_unique :content, :scope => :account_id,
      :message => lambda { |res,prop|
        %{Another blog entry (#%s) from %s already has that content.}.t(
          res.foreign_id, res.published_at.strftime('%Y-%m-%d')
        )
      }
    validates_is_unique :foreign_id, :scope => :account_id,
      :message => lambda { |o,prop|
        %{You already have another %s blog entry in the "%s" account with that foreign id (#%s).}.t(
          o.account.service.name, o.account.name_credential, o.send(prop.name)
        )
      }

    def one_word; truncate(title,15).inspect end

    def self.kreate(account_obj, foreign_id, author_str, content_str,
         keywords_str, published_at, status, title, current_user_obj, opts)
      published_at = to_time_or_throw published_at
      kind_of_or_throw :user, current_user_obj, User
      kind_of_or_throw 'date/time', published_at, DateTime
      kind_of_or_throw :account, account_obj, Account
      kind_of_or_throw :keywords, keywords_str, String
      md5 = MD5.new(content_str).to_s
      source_obj = opts.source ? Item.first_or_throw(:id => opts.source) : nil
      obj = self.create(
        :account        => account_obj,
        :foreign_id     => foreign_id,
        :author         => author_str,
        :content        => content_str,
        :content_md5    => md5,
        :keywords       => keywords_str,
        :published_at   => published_at,
        :source         => source_obj,
        :status         => status,
        :title          => title
      )
      obj.save or throw :invalid, ValidationErrors[obj]
      Event.kreate(:item_reflection_added, :of_item=>obj, :from_account=>account_obj, :by=>current_user_obj)
      obj
    end

    def self.remove(id_or_item, user_obj)
      assert_kind_of :user, user_obj, User
      item = id_or_item.kind_of?(Item) ? id_or_item : Item.first_or_throw(:id => id_or_item)
      unless (item.account.user == user_obj)
        throw :invalid, ValidationErrors["That item doesn't belong to you."]
      end
      item.destroy!
      Event.kreate :item_reflection_deleted, :item=>item, :by=>user_obj
      %{Removed the reflection of the item #{item.one_word}.}
    end
  end
end # module Hipe::SocialSync::Model
