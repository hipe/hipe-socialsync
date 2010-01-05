require "hipe-socialsync/interactive"
require 'abbrev'
require 'json'

module Hipe::SocialSync::Plugins
  class App
    include Hipe::Cli
    include Hipe::SocialSync::ControllerCommon
    include Hipe::Lingual::English

    cli.out.klass = Hipe::Io::GoldenHammer
    cli.does '-h','--help', 'overview of app commands'
    cli.default_command = :help

    cli.does(:transports)

    # this might be our first command-line-only interface.  keep it light
    def transports(opts=nil)
      @transports = cli.parent.application.transports
      @transports.load_all
      return "there are no transports." unless @transports.size > 0
      response = catch(:quit) do
        transport = prompt_trans
        begin
          puts hr
          puts transport.inspect
          puts hr
          command_names = transport.interface.commands.map{|x| x.name } << :quit
          list = command_names.map{|x| %{[#{x}]}}
          puts "enter <name> = <value>"
          puts "or type the beginning of"<<(list.size > 1 ? ' one of ' : ' ') <<
            en{np(:the,'command',list.size,:say_count => false)}.say
          puts en{list(list)}.or
          puts hr
          print ": "
          entered = gets.chomp
          cmd = prompt_enum(command_names.map{|_|_.to_s} << "", entered)
          if (cmd)
            case cmd
            when "": next
            when "quit": throw :quit, "goodbye, thank you"
            when String:
              begin
                resp = transport.send(cmd)  # we trust that the above only allowed thru publicly accessible cmd names
                puts resp.to_s
              rescue RuntimeError => e
                puts e.message
                next
              end
            else raise "huh?"
            end
          else
            if (/^[a-z_]+$/i =~ entered)
              puts "unrecognized or ambiguous command #{entered.inspect}"
              next
            elsif( tree = parse_assignment(entered) )
              unless(accessor = transport.class.attrs[tree.name])
                puts %|unrecognized property "#{tree.name}"|
                next
              end
              begin
                transport.send %{#{accessor.name}=}, tree.value
              rescue ArgumentError => e
                puts "Argument error: " << e.message << " for #{accessor.name}"
                next
              end
              next
            else
              puts "poorly formed request: #{entered.inspect}"
              next
            end
          end
        end while true
      end
    end

    def prompt_enum(command_names, enter)
      if enter == "" and command_names.include?("") then return "" end # abbrev doesn't like empty string
      abbrev = command_names.map{|x| x.to_s}.abbrev
      return abbrev[enter]
    end

    # @return [OpenStruct] tree with name, value or nil.  Raise ArgumentError on JSON parse failures
    def parse_assignment entered
      md = nil
      return nil unless (md = /^ *([a-z_]+) *= *([^ ]|[^ ].*[^ ]) *$/.match(entered))
      tree = Hipe::OpenStructExtended.new
      tree.name = md[1].to_sym
      raw_value = md[2]
      if ( md = /^'(.*)'$/.match(raw_value))
        # special case: turn single quotes into double quotes for JSON
        raw_value = %{"#{md[1]}"}
      elsif (! /^(?:true|false|-?\d+(?:\.\d+)?|".*")$/.match(raw_value))
        # special case: bare words get double quotes
        raw_value = %{"#{raw_value}"}
      end
      arr = begin
        JSON::parse %{[#{raw_value}]}
      rescue JSON::ParserError => e
        raise ArgumentError.new(e.message)
      end
      raise "Huh?" if arr.size > 1
      tree.value = arr[0]
      tree
    end

    def hr; '-' * 76 end

    def prompt_trans
      begin
        transports = @transports
        puts en{sp(np('available tranport', transports.keys.count ) )}.say << ':'
        puts @transports.keys.map{|x| x.to_s}.sort * ' '
        puts hr
        default = @transports.first.class.transport_name
        print "type a transport name or 'q' for quit [#{default}]: "
        name = gets.chomp
        name = default if name == ''
        throw(:quit, "thanks, goodbye.") if name == 'q'
        if @transports.has_key? name.to_sym
          return @transports.new_instance name.to_sym
        else
          puts %|unrecognized transport #{name.inspect}|
        end
      end while true
    end



    cli.does(:prune, 'erase temp files and files deemed not worthy.') do
      option('-h',&help)
      option('-d','--dry','dry run. show a preview of which folders/files you would off')
    end
    def prune opts
      out = cli.out.new
      out.string.flush_to << $stdout
      lizt = prune_files
      if lizt.size == 0
        out.puts "# (no files to prune.)"
      end
      lizt.each do |entry|
        fake_cmd = "rm -rf #{entry}"
        if (opts.dry)
          out.puts fake_cmd
          sleep(0.06)
        else
          out.puts fake_cmd
          FileUtils.remove_entry_secure entry
        end
      end
      out
    end

    # @return array of absolute (?) filenames
    def prune_files
      root = cli.parent.application.data_path
      these_folders =
      folder_list = [
        'coverage/',
        'pkg/'
      ].map{|x| Dir[File.join(root, x)] }.flatten # only the ones that exits
      these_files = Dir[File.join(root,'data/test.db.*')]
      these_folders + these_files
    end
  end
end
# ridiculously cool but ugly meta-programming in 29cbe04e59842d1091d6efddfc653fb921d8d047
