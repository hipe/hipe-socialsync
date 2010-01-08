module Hipe::SocialSync::Plugins
  class Accounts
    include Hipe::Cli
    include Hipe::SocialSync::Model
    include Hipe::SocialSync::ControllerCommon
    cli.out.klass = Hipe::SocialSync::GoldenHammer
    cli.description = "manage accounts"
    cli.default_command = 'help'
    cli.does '-h','--help', 'overview of account commands'

    cli.does(:add, "add an account"){
      option('-h',&help)
      required(:service_name,"the name of the service")
      required(:current_user_email, "the email of the person adding this account")
      optional(:name_credential,"the account name or email used to sign in to the service")
    }
    def add service_name, current_user_email, name_credential, opts
      out = cli.out.new
      user_obj = current_user(current_user_email)
      obj = Account.kreate(service_name, name_credential, user_obj)
      out.puts %{Added #{service_name} account of "#{name_credential}".}
      out
    end

    cli.does(:list, "show all accounts"){
      option('-h',&help)
      required(:current_user_email, "the email of the current user")
    }
    def list(current_user_email,opts)
      user_obj = current_user(current_user_email)
      accts = Account.all(:user=>user_obj,:order=>[:id.desc])
      out = cli.out.new
      out.suggested_template = 'tables'
      out.data.tables = [Hipe::Table.make do
        field(:id){|x| x.id}
        field(:service_name){|x| x.service.name}
        field(:name_credential){|x| x.name_credential}
        self.list = accts
      end]
      out
    end

    cli.does(:delete, "remove the account"){
      option('-h', &help)
      option('--object-id ID')
      optional(:service_name, 'name of service for the account you want to delete')
      optional(:name_credential, 'name on the account')
      optional(:current_user_email, 'who are you.')
    }
    def delete(service_name, name_credential, current_user_email, opts=nil)
      user_obj = current_user(current_user_email)
      if opts._table[:object_id]
        acct = Account.first_or_throw(:id => opts._table[:object_id])
        name_credential = acct.name_credential
        service_name = acct.service.name
      end
      out = cli.out.new
      out << Account.remove(service_name, name_credential, user_obj)
      out
    end
  end
end
