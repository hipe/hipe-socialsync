module Hipe::SocialSync::Plugins
  class Items
    include Hipe::Cli
    include Hipe::SocialSync::Model
    ItemModel = Hipe::SocialSync::Model::Item
    include Hipe::SocialSync::ControllerCommon
    cli.out.klass = Hipe::SocialSync::GoldenHammer
    cli.description = "blog entries"
    cli.does 'help','overview of item commands'
    cli.default_command = :help

    cli.does(:add, "add an entry and asociate it w/ an account") do
       option('-h','--help',&help)
       option('-d', '--[no-]dry', "Dry run.  Does everything the same but doesn't write to the database.")
       option('-s', '--source ID', "If this blog is a clone, what is the source item id?") do |it|
         it.must_be_positive_integer()
       end
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
            user_email, opts)
      out = cli.out.new
      user = current_user(user_email)
      svc = Service.first_or_throw(:name=>service_name)
      acct = Account.first_or_throw(:name_credential=>name_credential, :service=>svc, :user=>user)
      if (opts.dry)
        item = Object.new # openstruct won't work
        def item.id; 'dry-run' end
      else
        item = ItemModel.kreate(acct, foreign_id, author, content, keywords_str, published_at, status, title, user, opts)
      end
      out << %{Added blog entry (ours: ##{item.id}, theirs: ##{foreign_id}).}
      out
    end

    cli.does(:view, "show all details for an individual item") do
      option('-h',&help)
      required('id','id of the item to view')
    end
    def view(id, opts)
      item = ItemModel.first_or_throw(:id=>id)

      out = cli.out.new :suggested_template => :tables
      d = out.data
      d.tables = []

      item_table = self.class.table
      item_table.list = [item]
      item_table.axis = :horizontal
      d.tables << item_table

      events_table = Log.table
      events_table.list = item.events
      d.tables << events_table

      # clones_table = Events.table
      # clones_table.name = 'clones'
      # clones_table.show_only :id,:theirs,:user,:service,:name_cred,:published_at,:title,:excerpt,:last_event
      # clones_table.list = item.clones
      # d.tables << clones_table

      out
    end

    def self.table
      Hipe::Table.make do
        extend Hipe::SocialSync::ViewCommon
        self.name = 'items'
        field(:id){|x| x.id}
        field(:theirs){|x| x.foreign_id}
        field(:user){|x| x.account.user.one_word }
        field(:service){|x| x.account.service.name}
        field(:name_cred){|x| x.account.name_credential}
        field(:account){|x| x.account.one_word }
        field(:published_at){|x| x.published_at.strftime('%Y-%m-%d')}
        field(:title){|x| truncate(x.title,10) }
        field(:excerpt){|x| truncate(x.content,10) }
        field(:last_event){|x| x.last_event.as_relative_sentence(x) }
        field(:source){|x| x.source ? x.source.account.one_word : '(none)' }
        field(:targets, :label => 'target items'){|x| t=x.targets; t.size == 0 ? '(none)' : t.map{|y| y.account.one_word }}
        field(:target_accounts) do |x|
          x.target_accounts.size == 0 ? '(none)' : ( x.target_accounts.map{|y| y.account.one_word} * ',' )
        end
      end
    end

    # @todo below we hard-code svc names just for fun -- to play w/ optparse completion
    cli.does(:list, "show some items, maybe do something to them") do
      option('-h',&help)
      option('-u','--user EMAIL', 'items that belong to this sosy user [and...]')
      option('-s','--service NAME',['wordpress','tumblr'],'items that are from this service [and...]')
      option('-n','--name-credential NAME','items that are from the account with this username [and...]')
      option('-i','--ids IDS', 'comma-separated list of item ids') do |x|
        it.must_match(/^\d+(?:\d+)*$/)
      end
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

      table = self.class.table
      table.show_only :id,:theirs,:user,:account,:published_at,:title,:excerpt,:source,:targets,:target_accounts

      table.field[:target_accounts].show if acct # this is just cosmetic :/

      items = get_items(table, user, svc, acct)
      items[0].last_event

      out = cli.out.new :suggested_template => :tables
      if command_name
        sub_out = do_aggregate(items, command_name, current_user_email, opts)
        acct.reload if acct
        items = get_items(table, user, svc, acct)
        out.merge! sub_out
      end
      table.list = items
      out.data.tables = [table]
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
        else; ItemModel.all end
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
      out << ItemModel.remove(id_or_item, user)
      out
    end
  end
end
