module Hipe::SocialSync::Plugins
  class Services
    include Hipe::Cli
    include Hipe::SocialSync::Model
    cli.out = :golden_hammer
    
    cli.does '-h --help', 'display help for services'  
    cli.does(:add, "add a service to the list"){
      option('-h',&help)      
      required(:name,"any ol' name you want, not an existing name")
      required(:email,"")
    }
    def add(name, email,opts)
      user = User.first!(:email=>email)
      Service.kreate name, user
      cli.out.puts %{created service "#{name}". Now there are #{Service.count} services.}
    end
    
    cli.does :list, "show all services"
    def list(*args)
      all = Service.all :order => [:name.asc]
      all.each{|x| @out.puts sprintf('%-5d  %20s', x.id, x.email)}
      cli.out.puts %{(#{Service.count} services)}
    end
    
    cli.does(:delete, "remove the service."){
      option('-h',&help)
      required(:name, 'name of service to delete')
    }
    def delete name
      cli.out.puts "not implemented!"      
    end
  end
end
  