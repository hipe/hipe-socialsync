module Hipe::SocialSync::Plugins
  class Services
    include Hipe::Cli::App
    include Hipe::SocialSync::Model
    
    def initialize
      @out = cli.out
    end
        
    cli.does '-h --help'    
    cli.does :add, {
      :description => "add a service to the list",
      :required => [
        {:name => :NAME, :description => "any ol' name you want, not an existing name"},
        {:name => :EMAIL,:description => "don't ask"}        
      ]
    }
    def add(name, email)
      user = User.first(:email=>email)
      Service.kreate name, user
      @out.puts %{created service "#{name}". Now there are #{Service.count} services.}
    end
    
    cli.does :list, {
      :description => "show all services"
    }
    def list
      all = Service.all :order => [:name.asc]
      all.each{|x| @out.puts sprintf('%-5d  %20s', x.id, x.email)}
      @out.puts %{(#{Service.count} services)}
    end
    
    cli.does :delete, {
      :descritpion => "remove the service.",
      :required => [
        { :name => :NAME }
      ]
    }
    def delete name
      @out.puts "not implemented!"      
    end
  end
end
  