module Hipe::SocialSync::Plugins
  class Service
    include Hipe::Cli::App
    cli.does :add, {
      :description => "add a service to the list",
      :required => [
        {:name => :NAME, :description => "any ol' name you want, not an existing name"}
      ]
    }
    def add(name)
      
    end
    
    cli.does :list, {
      :description => "show all services"
    }
    def list
      
    end
    
    cli.does :delete, {
      :descritpion => "remove the item from the list",
      :required => [
        { :name => :NAME }
      ]
    }
    def delete name
      
    end
  end
end
  