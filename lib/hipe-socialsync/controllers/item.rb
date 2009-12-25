require 'hipe-core/lingual/ascii-typesetting'
module Hipe::SocialSync::Plugins
  class Item
    include Hipe::Cli
    include Hipe::AsciiTypesetting::Methods
    include Hipe::SocialSync::Model
    cli.out.class = Hipe::Io::GoldenHammer
    cli.description = "blog entries"
    cli.does 'help'
    cli.does(:add, "add an entry and asociate it w/ an account") do    
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
    def add(service_name, name_credential, foreign_id, author, content, keywords_str,published_at,status,title,user_email)
      out = cli.out.new
      user = User.first!(:email=>user_email)
      acct = Account.first!(:name_credential=>name_credential, :service_name=>service_name, :user=>user)
      item=Item.kreate(acct, foreign_id, author, content,keywords_str,published_at,status,title,user)
      out << %{created item #{item.id}}
      out
    end
    cli.does(:list, "show some itemt") do
    end
    def list(*args)
      out = cli.out.new
      all = Item.all :order => [:published_at.desc]
      all.each{|x| out.puts sprintf('%-5d  %10s %8s %20s %30s', x.id, x.published_at, x.account.service.name, x.author, 
        truncate(x.content,27))}
      out.puts %{(#{Item.count} items)}
      out
    end
  end
end
