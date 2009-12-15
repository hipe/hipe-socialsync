module Hipe::SocialSync::Plugins
  class Users
    include Hipe::Cli
    include Hipe::SocialSync::Model
    cli.out = :golden_hammer    
    cli.description = "it's premature to add users, don't you think?"
    cli.does '-h','--help'
    cli.does(:add, "add a user to the list"){
      required('email', "any ol' name you want, not an existing name")
      required('admin_email',"the person acting as the admin")
    }
    def add email, admin_email
      admin = User.first(:email=>admin_email)
      User.kreate email, admin
      cli.out.puts %{created user "#{email}". Now there are #{User.count} users.}
    end
    
    cli.does(:list, "show all users")
    def list(*args)
      out = cli.out
      all = User.all :order => [:email.asc]
      all.each{|x| out.puts sprintf('%-5d  %20s', x.id, x.email)}
      out.puts %{(#{User.count} users)}
      out
    end

    cli.does(:delete,"delete user accounts"){
      required('email')
    }
    def delete email
      @out.puts "not implemented!"
    end
  end
end
