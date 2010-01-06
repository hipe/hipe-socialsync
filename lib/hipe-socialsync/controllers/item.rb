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
      required 'item_id'
      required 'target_service_name'
      required 'target_name_credential'
      required 'current_user_email'
    end

    def add_target_account item_id, target_service_name, target_name_credential, current_user_email, opts
      user = current_user current_user_email
      svc = Service.first_or_throw :name=>target_service_name
      acct = Account.first_or_throw :name_credential=>target_name_credential, :service=>svc, :user=>user
      item = ItemModel.first_or_throw :id => item_id
      item.account # @todo
      existing = item.target_accounts.first(:account => acct)
      if (existing)
        argument_error("Account #{acct.one_word} has already been targeted by item #{item.one_word}.")
      else
        item.target_accounts.new(:account => acct)
        item.save
        Event.kreate :target_account_added, :from_item => item, :to_account => acct, :by => user
        cli.out.new("Added target #{acct.one_word} to item #{item.one_word}.")
      end
    end

    cli.does(:remove_target_accounts, "add to the list of targeted accounts(s)") do
      option   '-h'
      required 'item_id'
      required 'current_user_email'
    end
    def remove_target_accounts item_id, current_user_email, opts
      user = current_user current_user_email
      item = ItemModel.first_or_throw :id => item_id
      size = item.target_accounts.size
      item.account #@todo
      if (size == 0)
        argument_error("Item #{item.one_word} is already cleared of targets.")
      else
        rs = item.target_accounts.map{|targeting| targeting.destroy}
        num_destroyed = rs.select{|x| x==true}.size
        Event.kreate :target_accounts_removed, :from_item => item, :by => user
        cli.out.new("Removed "<<en{np('target',num_destroyed)}.say<<" from item #{item.one_word}.")
      end
    end
  end
end
