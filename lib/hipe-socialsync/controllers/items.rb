require 'hipe-core/lingual/ascii-typesetting'
module Hipe::SocialSync::Plugins
  class Items
    include Hipe::Cli
    include Hipe::AsciiTypesetting::Methods
    include Hipe::SocialSync::Model
    include Hipe::SocialSync::ControllerCommon    
    cli.out.klass = Hipe::SocialSync::GoldenHammer
    cli.description = "blog entries"
    cli.does 'help','overview of item commands'
    cli.does(:add, "add an entry and asociate it w/ an account") do
       option('-h','--help',&help)
       required('service-name')
       required('name-credential')
       required('foreign-id')
       required('author')
       required('content-str')
       required('keywords-str')
       required('published_at')
       required('status')
       required('title')
       required('current_user_email')
    end
    def add(service_name, name_credential, foreign_id, 
            author, content, keywords_str,
            published_at, status, title, 
            user_email, o)
      out = cli.out.new
      user = current_user(user_email)
      svc = Service.first_or_throw(:name=>service_name)
      acct = Account.first_or_throw(:name_credential=>name_credential, :service=>svc, :user=>user)
      item = Item.kreate(acct, foreign_id, author, content, keywords_str, published_at, status, title, user)
      out << %{Added blog entry (ours: ##{item.id}, theirs: ##{foreign_id}).}
      out
    end

    cli.does(:list, "show some items") do
      option('-h',&help)
      option('-m','--mine')
      option('-s','--service NAME','items to delete must be from this service [and...]')
      option('-n','--name-credential NAME','items to delete must be from the account with this username [and...]')
      required('current_user_email')
    end
    def list(current_user_email,opts)
      user = current_user(current_user_email)
      if ( x = [:service,:name_credential] & opts.keys ).size > 0 and ! opts.all
        raise ArgumentError.new(%{to use #{x.map{|y| %{"#{y}"}}*' and '} please indicate "--all"})
      end      
      throw :invalid, ValidationErrors[%{If you indicate a name_credential please indicate a service}] if 
        (opts.name_credential && ! opts.service)
            
      items = Item.all(:order => [:published_at.desc])
      if (opts.mine)
        items = Item.of_user(user)
      end
      if (opts.service)
        svc = Service.first_or_throw(:name => opts.service)
        if (opts.name_credential)
          acct = Account.first_or_throw(:service=>svc)
          items = items.of_account(acct)
        else
          items = items.of_service(svc)
        end
      end
      
      out.data.common_template = 'list'
      out.data.list = items
      out.data.klass = Item
      out.data.headers = ['id','service','name cred','user','published at', 'title','excerpt']
      out.data.ascii_format_row = lambda{|x| ' %5s |%13s |%13s |%13s |%20s |%10s |%10s'.t(*x)}
      out.data.row = lambda{|x| 
      [
        x.id, 
        x.service.name, 
        x.account.name_credential,
        x.account.user.email,
        x.published_at.strftime('%Y-%m-%d %H:%I:%S'), 
        truncate(x.content,10),
        truncate(x.title,10)
      ]}
      out
    end

    cli.does(:delete, "remove the reflection of the item") do
      required('item_id', "item id to delete")       
      required('current_user_email')
    end
    def delete(id,current_user_email,opts)
      out = cli.out.new
      user = current_user(current_user_email)      
      out << Item.remove(id, user)
      out
    end
  end
end
