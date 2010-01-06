module Hipe::SocialSync::Plugins
  class Item
    include Hipe::Cli
    include Hipe::SocialSync::Model
    ItemModel = Hipe::SocialSync::Model::Item
    include Hipe::SocialSync::ControllerCommon
    include Hipe::SocialSync::ViewCommon
    cli.out.klass = Hipe::SocialSync::GoldenHammer
    cli.description = "edit an individual entry"
    cli.does 'help','overview of item commands'
    cli.default_command = :help

    cli.does(:add_target_account, "add to the list of targeted accounts(s)") do
      option   '-h'
      required('item_ids') do |x|
        x.must_match(/^(\d+(?:,\d+)*)$/)
      end
      required 'target_service_name'
      required 'target_name_credential'
      required 'current_user_email'
    end

    def add_target_account item_ids, target_service_name, target_name_credential, current_user_email, opts
      user = current_user current_user_email
      svc = Service.first_or_throw :name=>target_service_name
      acct = Account.first_or_throw :name_credential=>target_name_credential, :service=>svc, :user=>user
      items = ItemModel.all(:id => item_ids[0].split(','))
      return cli.out.new("no matching item(s) found for #{item_ids}") unless items.size > 0
      out = cli.out.new
      items.each do |item|
        item.account # @todo
        # existing = item.target_accounts.first(:account => acct) #@todo
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
      option   '-h'
      required('item_ids'){|x| x.must_match(/^(\d+(?:,\d+)*)$/) }
      required 'current_user_email'
    end
    def remove_target_accounts item_ids, current_user_email, opts
      user = current_user current_user_email
      items = ItemModel.all(:id => item_ids[0].split(','))
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
