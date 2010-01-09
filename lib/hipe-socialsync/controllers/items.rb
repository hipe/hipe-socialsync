module Hipe::SocialSync::Plugins
  class Items
    include Hipe::Cli
    include Hipe::SocialSync::Model
    include Hipe::SocialSync::ControllerCommon
    include Hipe::SocialSync::ViewCommon
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
        out << %{Added blog entry (ours: ##{item.id}, theirs: ##{foreign_id}).}
      else
        validation_errors = catch(:invalid) do
          item = Item.kreate(acct, foreign_id, author, content, keywords_str, published_at, status, title, user, opts)
          out << %{Added blog entry (ours: ##{item.id}, theirs: ##{foreign_id}).}
          out.data.item = item
          nil
        end
        if validation_errors
          out.errors << validation_errors.to_s
        end
      end
      out
    end

    cli.does(:view, "show all details for an individual item") do
      option('-h',&help)
      required('id','id of the item to view')
    end
    def view(id, opts)
      item = Item.first_or_throw(:id=>id)

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
      option('-a','--account ID', 'items that are from this account id [and...]')
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
      command_name = nil if command_name == "" # @todo rack nils
      if (command_name && ! current_user_email)
      #unless [0,2].include? [current_user_email, command_name].compact.size
        argument_error(%{If you indicate a command (#{command_name.inspect})}<<
          %{ you must indicate a user (#{current_user_email.inspect})})
      end

      user = opts.user ? User.first_or_throw(:email => opts.user) : nil
      svc  = opts.service ? Service.first_or_throw(:name => opts.service) : nil
      if (opts.name_credential && (missing = [:service,:user] - opts._table.keys).size > 0)
        argument_error(%{To search with name credential you must indicate a #{missing.map{|x| %{#{x}}}*' and a '}.})
      end

      if opts.name_credential
        argument_error("You can't indicate both a name credential and an account id") if opts.account
        acct = Account.first_or_throw(:service => svc, :name_credential => opts.name_credential)
      elsif opts.account
        acct = Account.first_or_throw(:id => opts.account)
      else
        acct = nil
      end

      if (acct && user && acct.user != user)
        argument_error(%{You can't view items of other users})
      end

      table = self.class.table
      table.show_only :id,:theirs,:user,:account,:published_at,:title,:excerpt,:source,:targets,:target_accounts

      table.field[:target_accounts].show if acct # this is just cosmetic :/

      items = get_items(table, user, svc, acct)
      items[0].last_event

      out = cli.out.new :suggested_template => :tables
      out.data.user = user
      out.data.service = svc
      out.data.account = acct
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
        else; Item.all end
      items
    end
    def do_aggregate list, command, current_user_identifier, opts
      current_user_obj = current_user(current_user_identifier)
      argument_error("Invalid aggregate command: #{command.inspect}") unless ['delete'].include?(command)
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

    cli.does(:delete, "remove the reflection of the item(s)") do
      option('-h',&help)
      required('item_ids', "comma-separated list of item ids to delete") do |it|
        it.must_match(/^\d+(?:,\d+)*$/) unless it.kind_of?(Item)
        it
      end
      required('current_user_email')
    end
    def delete items, current_user_email, opts
      user = current_user current_user_email
      case items
        when Item: items = [items]
        when String: items = items.split(',')
        else argument_error("very unexpected class for items: #{items.inspect}")
      end
      out = cli.out.new # (:on_data_collision => :pluralize)
      items.each do |item_identifier|
        out.merge! Item.remove(item_identifier, user)
      end
      out
    end

    cli.does(:add_target_account, "add to the list of targeted accounts(s)") do
      option('-h','--help',&help)
      required('item_ids') do |x|
        x.must_match(/^\d+(?:,\d+)*$/)
      end
      required 'account', 'account identifer - either a primary key or "<service name>/<name credential>"'
      required 'current_user_email'
    end

    def add_target_account item_ids, account_identifier, current_user_email, opts
      user = current_user current_user_email
      acct = Account.first_from_identifier_or_throw account_identifier
      items = Item.all(:id => item_ids.split(','))
      return cli.out.new("no matching item(s) found for #{item_ids}") unless items.size > 0
      out = cli.out.new
      items.each do |item|
        item.account # @todo
        existing_list = item.target_accounts.select{|x| x.account = acct }
        if existing_list.size > 0  # existing
          argument_error("Account #{acct.one_word} has already been targeted by item #{item.one_word}.")
        else
          item.target_accounts.new(:account => acct)
          item.save
          Event.kreate :target_account_added, :from_item => item, :to_account => acct, :by => user
          out.puts("Added target #{acct.one_word} to item #{item.one_word}.")
        end
      end
      out
    end

    cli.does(:remove_target_accounts, "add to the list of targeted accounts(s)") do
      option('-h','--help',&help)
      required('item_ids'){|x| x.must_match(/^(\d+(?:,\d+)*)$/) }
      required 'current_user_email'
    end
    def remove_target_accounts item_ids, current_user_email, opts
      user = current_user current_user_email
      items = Item.all(:id => item_ids[0].split(','))
      return cli.out.new("no matching item(s) found") if items.size == 0
      out = cli.out.new
      items.each do |item|
        size = item.target_accounts.size
        item.account #@todo
        if (size == 0)
          argument_error("Item #{item.one_word} is already cleared of targets.")
        else
          rs = item.target_accounts.map{|targeting| targeting.destroy}
          num_destroyed = rs.select{|x| x==true}.size
          Event.kreate :target_accounts_removed, :from_item => item, :by => user
          out.puts("Removed "<<en{np('target',num_destroyed)}.say<<" from item #{item.one_word}.")
        end
      end
      out
    end
  end
end
