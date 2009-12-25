module Hipe::SocialSync::Plugins
  class Accounts
    include Hipe::Cli
    include Hipe::SocialSync::Model
    cli.out.class = Hipe::SocialSync::GoldenHammer
    cli.description = "manage accounts"
    cli.default_command = 'help'
    cli.does '-h','--help'
    
    cli.does(:add, "add an account"){
      option('-h',&help)
      required(:service_name,"the name of the service")
      required(:current_user_email, "the email of the person adding this account")      
      optional(:name_credential,"the account name or email used to sign in to the service")      
    }
    def add service_name, current_user_email, name_credential, opts
      out = cli.out.new     
      user_obj = User.first_or_throw :email=>current_user_email
      obj = Account.kreate(service_name, name_credential, user_obj)            
      out.puts %{Added #{service_name} account of "#{name_credential}".}
      out
    end

    cli.does(:list, "show all accounts"){
      option('-h',&help)
      required(:current_user_email, "the email of the current user")            
    }
    def list(current_user_email,opts)
      out = cli.out.new
      user_obj = User.first_or_throw :email=>current_user_email      
      accts = Account.all(:user=>user_obj,:order=>[:id.desc])
      out.data.common_template = 'list'      
      out.data.list = accts
      out.data.klass = Account
      out.data.row = lambda{|x| ['%-5d'.t(x.id),'%20s'.t(x.service.name), '%20s'.t(x.name_credential)]}
      out
    end

    cli.does(:delete, "remove the account"){
      option('-h', &help)
      required(:service_name, 'name of service for the account you want to delete')   
      required(:name_credential, 'name on the account')            
      required(:current_user_email, 'who are you.')
    }
    def delete(service_name, name_credential, current_user_email, opts=nil)
      user_obj = User.first_or_throw :email=>current_user_email 
      out = cli.out.new
      out << Account.remove(service_name, name_credential, user_obj)
      out
    end
  end
end
