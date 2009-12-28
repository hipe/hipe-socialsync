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

    # @todo below we hard-code svc names just for fun -- to play w/ optparse completion
    cli.does(:list, "show some items, maybe do something to them") do
      option('-h',&help)
      option('-u','--user EMAIL', 'items that belong to this sosy user [and...]')
      option('-s','--service NAME',['wordpress','tumblr'],'items that are from this service [and...]')
      option('-n','--name-credential NAME','items that are from the account with this username [and...]')
      optional('COMMAND', 'one day, aggregate actions')
      optional('current_user_email','if you are going to do anything destructive')
    end

    def list(command_name, current_user_email, opts)
      unless [0,2].include? [current_user_email, command_name].compact.size
        argument_error(%{If you indicate a command (#{command_name.inspect})}<<
          %{ you must indicate a user (#{current_user_email.inspect})})
      end

      user = opts.user ? User.first_or_throw(:email => opts.user) : nil
      svc  = opts.service ? Service.first_or_throw(:name => opts.service) : nil
      if (opts.name_credential && (missing = [:service,:user] - opts._table.keys).size > 0)
        argument_error(%{To search with name credential you must indicate a #{missing.map{|x| %{#{x}}}*' and a '}.})
      end
      acct = opts.name_credential ? Account.first_or_throw(:service => svc, :name_credential => opts.name_credential) : nil
      if (acct && user && acct.user != user)
        argument_error(%{You can't view items of other users})
      end

      controller = self
      table = Hipe::Table.make do
        field(:id){|x| x.id}
        field(:theirs){|x| x.foreign_id}
        field(:user){|x| x.account.user.one_word }
        field(:service){|x| x.account.service.name}
        field(:name_cred){|x| x.account.name_credential}
        field(:published_at){|x| x.published_at.strftime('%Y-%m-%d %H:%I:%S')}
        field(:title){|x| controller.truncate(x.title,10) }
        field(:excerpt){|x| controller.truncate(x.content,10) }
      end

      items = get_items(table, user, svc, acct)
      out = cli.out.new
      if command_name
        sub_out = do_aggregate(items, command_name, current_user_email, opts)
        acct.reload if acct
        items = get_items(table, user, svc, acct)
        out.merge! sub_out
      end
      out.data.common_template = 'table'
      table.list = items
      out.data.table = table
      out
    end
    def get_items(table, user, svc, acct)
      # see #datamapper at 2009-12-28 3:30am for a discussion of how to do this query
      items =
        if (acct) then acct.items
        elsif (svc)
          table.field[:service].hide()
          if (user)
            table.field[:user].hide()
            amazing = user.items & svc.items
            amazing.map   # strange bug when you call amazing.each
          else
            svc.items
          end
        elsif (user)
          table.field[:user].hide()
          user.items
        else; Item.all end
      items
    end
    def do_aggregate list, command, current_user_identifier, opts
      current_user_obj = current_user(current_user_identifier)
      argument_error("Invalid command: #{command.inspect}") unless ['delete'].include?(command)
      out = cli.out.new
      if (list.count < 0)
        out.messages << "There were no items to #{command}."
      else
        list.each do |item|
          out.messages << delete(item, current_user_obj, nil)
        end
      end
      out
    end

    cli.does(:delete, "remove the reflection of the item") do
      option('-h',&help)
      required('item_id', "item id to delete")
      required('current_user_email')
    end
    def delete id_or_item, current_user_email, opts
      out = cli.out.new
      user = current_user(current_user_email)
      out << Item.remove(id_or_item, user)
      out
    end
  end
end
