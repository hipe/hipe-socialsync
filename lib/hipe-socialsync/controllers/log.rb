module Hipe::SocialSync::Plugins
  class Log
    include Hipe::Cli
    include Hipe::SocialSync::Model
    include Hipe::SocialSync::ControllerCommon
    cli.out.klass = Hipe::SocialSync::GoldenHammer
    cli.description = "activity log"
    cli.does 'help','overview of log commands'

    # @todo below we hard-code svc names just for fun -- to play w/ optparse completion
    cli.does(:list, "view all log entries") do
      option('-h',&help)
      option('-l','--limit')
      option('-s','--since')
    end

    def list(opts)
      controller = self
      items = Event.all()
      table = Hipe::Table.make do
        field(:id){|event| event.id}
        field(:happened_at){|e| e.happened_at.strftime('%Y-%m-%d %H:%I:%S')}        
        field(:type){|e| controller.humanize_lite(e.type) }
        field(:details,:align=>:left) do |e| 
          e.details.map{|x| %{#{x.type} => #{x.target.one_word}} }*' '
        end
      end
      out = cli.out.new
      out.data.common_template = 'table'
      table.list = items
      out.data.table = table
      out
    end
  end
end
