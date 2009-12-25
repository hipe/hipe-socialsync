require 'hipe-core/lingual/ascii-typesetting'
module Hipe::SocialSync::Plugins
  class Items
    include Hipe::Cli
    include Hipe::AsciiTypesetting::Methods
    include Hipe::SocialSync::Model
    cli.out.class = Hipe::SocialSync::GoldenHammer
    cli.description = "blog entries"
    cli.does 'help'
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
    def add(service_name, name_credential, foreign_id, author, content, keywords_str,published_at,status,title,user_email,o)
      out = cli.out.new
      user = User.first_or_throw(:email=>user_email)
      svc = Service.first_or_throw(:name=>service_name)
      acct = Account.first_or_throw(:name_credential=>name_credential, :service=>svc, :user=>user)
      item = Item.kreate(acct, foreign_id, author, content, keywords_str, published_at, status, title, user) 
      out << %{Added blog entry (ours: ##{item.id}, theirs: ##{foreign_id}).}
      out
    end
    
    cli.does(:list, "show some items") do 
      required('current_user_email')
    end
    def list(current_user_email,*args)
      user = User.first_or_throw(:email=>current_user_email)
      out = cli.out.new
      out.data.common_template = 'list'
      out.data.list = Item.all :order => [:published_at.desc]
      out.data.klass = Item
      out.data.header = ['id','published at','service name','author name','content']
      out.data.row = lambda do |x| 
        ['%-5d'.t(x.id), '%10s'.t(x.published_at.strftime('%Y-%m-%d %H:%M:%S')),
          '%8s'.t(x.account.service.name), '%20s'.t(x.author), '%30s'.t(truncate(x.content,27))
        ]
      end
      out
    end
  end
end
