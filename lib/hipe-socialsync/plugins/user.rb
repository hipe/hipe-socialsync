module Hipe::SocialSync::Plugins
  class User
    include Hipe::Cli::App
    cli.does :add, {
      :description => "add a user to the list",
      :required => [
        {:name => :EMAIL, :description => "any ol' name you want, not an existing name"}
      ]
    }
    def add email
      User.kreate email
      @out.puts %{created user "#{email}". Now there are #{User.count} users.}
    end
    
    cli.does :list, {
      :description => "show all users"
    }
    def list
      all = User.all :order => [:email.asc]
      all.each{|x| @out.puts x.email }
      @out.puts %{(#{Users.count} users.)}
    end

    cli.does :delete, {
      :descritpion => "deletes the user account",
      :required => [
        { :name => :EMAIL }
      ]
    }
    def delete email
      
      
    end
  end
end
