module Hipe::SocialSync::Plugins
  class Users
    include Hipe::Cli::App    
    include Hipe::SocialSync::Model

    def initialize
      @out = self.cli.out
    end
    
    cli.does '-h --help'
    cli.does :add, {
      :description => "add a user to the list",
      :required => [
        {:name => :EMAIL, :description => "any ol' name you want, not an existing name"}, 
        {:name => :ADMIN_EMAIL, :description => "the person acting as the admin"}        
      ]
    }
    def add email, admin_email
      admin = User.first(:email=>admin_email)
      User.kreate email, admin
      @out.puts %{created user "#{email}". Now there are #{User.count} users.}
    end
    
    cli.does :list, {
      :description => "show all users"
    }
    def list
      all = User.all :order => [:email.asc]
      all.each{|x| @out.puts sprintf('%-5d  %20s', x.id, x.email)}
      @out.puts %{(#{User.count} users)}
    end

    cli.does :delete, {
      :descritpion => "deletes the user account",
      :required => [
        { :name => :EMAIL }
      ]
    }
    def delete email
      @out.puts "not implemented!"
    end
  end
end
