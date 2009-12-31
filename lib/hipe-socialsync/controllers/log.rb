module Hipe::SocialSync::Plugins
  class Log
    include Hipe::Cli
    include Hipe::SocialSync::Model
    include Hipe::SocialSync::ControllerCommon
    include Hipe::SocialSync::ViewCommon
    extend Hipe::SocialSync::ViewCommon
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

    def self.table
      formatter = self
      Hipe::Table.make do
        self.name = 'events'
        field(:id){|event| event.id}
        field(:happened_at){|e| formatter.date_format(e.happened_at) }
        field(:type){|e| formatter.humanize_lite(e.type) }
        field(:details,:align=>:left) do |e|
          #e.as_relative_sentence(nil,:omit => )
          e.details.map{|x| %{#{formatter.humanize_lite(x.type)} #{x.target.one_word}} }*' '
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
      table = self.class.table
      items = Event.all(query)
      out = cli.out.new :suggested_template => :tables
      table.list = items
      out.data.tables = [table]
      out
    end
  end
end
