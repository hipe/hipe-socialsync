module Hipe::SocialSync::Plugins
  class Users
    include Hipe::Cli
    include Hipe::SocialSync::Model
    include Hipe::SocialSync::ControllerCommon
    cli.out.klass = Hipe::Io::GoldenHammer
    cli.description = "it's premature to add users, don't you think?"
    cli.does 'help', 'overview of user commands'
    cli.does(:add, "add a user to the list"){
      option('-h',&help)
      required('email', "any ol' name you want, not an existing name")
      required('admin_email',"the person acting as the admin")
    }
    def add email, current_user_email, opts
      out = cli.out.new
      admin = current_user(current_user_email)
      response = User.kreate email, admin
      out.puts %{Created user "#{email}". Now there are #{User.count} users.}
      out
    end

    cli.does(:list, "show all users")
    def list(*args)
      out = cli.out.new
      all = User.all :order => [:email.asc]
      all.each{|x| out.puts sprintf('%-5d  %20s', x.id, x.email)}
      out.puts %{(#{User.count} users)}
      out
    end

    cli.does(:delete,"delete user accounts"){
      option('-h',&help)
      required('email')
      required('admin')
    }
    def delete email, admin, opts=nil
      out = cli.out.new
      out << User.remove(email, admin)
      out
    end
  end
end
