module Hipe::SocialSync::Plugins
  class Log
    include Hipe::Cli
    include Hipe::SocialSync::Model
    include Hipe::SocialSync::ControllerCommon
    include Hipe::SocialSync::ViewCommon
    cli.out.klass = Hipe::SocialSync::GoldenHammer
    cli.description = "activity log"
    cli.does 'help','overview of log commands'
    cli.default_command = 'list'

    # @todo below we hard-code svc names just for fun -- to play w/ optparse completion
    cli.does(:list, "view all log entries") do
      option('-h',&help)
      option('-l','--limit NUM', :default => '38'){|it| it.must_be_integer }
      option('-b','--before DATE'){|it| DateTime.parse(it) }
    end

    def table
      controller = self
      Hipe::Table.make do
        self.name = 'events'
        field(:id){|event| event.id}
        field(:happened_at){|e| e.happened_at.strftime('%Y-%m-%d %H:%I:%S')}
        field(:type){|e| controller.humanize_lite(e.type) }
        field(:details,:align=>:left) do |e|
          e.details.map{|x| %{#{x.type} #{x.target.one_word}} }*' '
        end
      end
    end

    def list(opts)
      controller = self
      query = {
        :limit => opts.limit,
        :order => [:happened_at.desc]
      }
      if (opts.before)
        query[:happened_at.lt] = opts.before
      end
      table = table
      items = Event.all(query)
      out = cli.out.new
      out.data.common_template = 'table'
      table.list = items
      out.data.table = table
      out
    end
  end
end
