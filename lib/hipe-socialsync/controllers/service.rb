module Hipe::SocialSync::Plugins
  class Services
    include Hipe::Cli
    include Hipe::SocialSync::Model
    include Hipe::SocialSync::ControllerCommon
    cli.out.klass = Hipe::SocialSync::GoldenHammer
    cli.description = "manage services"
    cli.default_command = 'help'
    cli.does '-h','--help', 'overview of service commands'

    cli.does(:add, "add a service to the list"){
      option('-h',&help)
      required(:name,"any ol' name you want, not an existing name")
      required(:current_user_email, "the email of the person adding this service")
    }
    def add name, email, opts
      out = cli.out.new
      admin = current_user(email)
      Service.kreate name, admin
      # out.puts %{created service "#{name}". Now there are #{Service.count} services.}
      out.puts %{Created service "#{name}".  Now }+Hipe::Lingual.en{sp(np('service',Service.count))}.say+'.'
      out
    end

    cli.does(:list, "show all services"){
      option('-h',&help)
    }
    def list(opts)
      out = cli.out.new
      out.data.common_template = 'table'
      svcs = Service.all :order => [:name.asc]
      out.data.table = Hipe::Table.make do
        field(:id){|x| x.id}; field(:name){|x| x.name}
        self.list = svcs
      end
      out
    end

    cli.does(:delete, "remove the service."){
      option('-h', &help)
      required(:name, 'name of service to delete')
      required(:current_user_email, 'who are you.')
    }
    def delete name, current_user_email, opts=nil
      out = cli.out.new
      out << Service.remove(name, current_user(current_user_email))
      out
    end
  end
end
