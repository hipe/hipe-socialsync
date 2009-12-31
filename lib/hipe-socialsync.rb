#!/usr/bin/env ruby
require 'rubygems'
require 'ruby-debug'
require 'hipe-cli'
require 'hipe-core/infrastructure/exception-like'
require 'hipe-core/struct/open-struct-extended'
require 'hipe-core/struct/table'
require 'hipe-core/lingual/ascii-typesetting'
require 'dm-core'
require 'dm-aggregates'

module Hipe
  module SocialSync
    VERSION = '0.0.3'
    DIR = File.expand_path('../..',__FILE__)
    module Plugins; end
    module ExceptionUpgrade
      def valid?; false end
    end
    class Exception < Hipe::Exception
      include Hipe::ExceptionLike
      self.modules = [Hipe::SocialSync]
      #def self.upgrade(exception)
      #  return if exception.respond_to? :valid?
      #  exception.extend ExceptionUpgrage
      #  exception
      #end
      def valid?; false end
    end
    # soft exception and graceful list last seen 30db43a9797bd11e41c2616aaefc956e730f7149
    class GoldenHammer < Hipe::Io::GoldenHammer
      def initialize(str=nil)
        super()
        @string << str.to_s if str
      end
      def to_s
        if (!valid?)
          super
        elsif (data.common_template)
          send(%{#{data.common_template}_template})
        else
          super
        end
      end
      def table_template
        lines = [data.table.render(:ascii)]
        lines.concat all_messages
        lines * "\n"
      end
      def tables_template
        lines = []
        data.tables.each do |table|
          lines << table.render(:ascii)
        end
        lines.concat all_messages
        lines * "\n"
      end
      #def list_template
      #  s = Hipe::Io::BufferString.new
      #  formatter = data.ascii_format_row || lambda{|row| row * ' ' }
      #  if data.headers
      #    # s.puts(formatter.call(data.headers).gsub(' ','_'))
      #    s.puts(formatter.call(data.headers))
      #    s.puts(formatter.call(Array.new(data.headers.size)).gsub(' ','-'))
      #  end
      #  data.list.each do |item|
      #    s.puts(formatter.call(data.row.call(item)))
      #  end
      #  s.puts %{#{data.list.count} #{Extlib::Inflection.pluralize(data.human_name || data.klass.human_name)}}
      #  s
      #end
    end
    class App
      include Hipe::Cli
      cli.program_name = 'sosy' # necessary b/c when running it from bacon, its name became 'bacon'
      cli.description = 'Import your wordpress blogs into tumblr.'
      cli.option('-e','--env ENV',['mu','test','dev'],'environment', :default=>'dev')
      cli.does '-h','--help' , 'display this help screen (for the sosy app)'
      cli.default_command = :help
      cli.out.klass = GoldenHammer
      cli.plugins.add_directory(%{#{DIR}/lib/hipe-socialsync/controllers}, Plugins, :lazy=>true)
      cli.config = OpenStruct.new({
        :db => Hipe::OpenStructExtended.new({   # @todo Gash
          :test => %{sqlite3://#{Hipe::SocialSync::DIR}/data/test.db},
          :dev  => %{sqlite3://#{Hipe::SocialSync::DIR}/data/dev.db}
        })
      })

      def initialize(startup_argv=nil)
        if (startup_argv)
          @prepend = startup_argv.dup
        else
          @prepend = []
        end
      end

      def db_path
        connect_string = cli.config.db[@univ.env]
        unless(md=%r{^sqlite3://(.*)$}.match(connect_string))
          raise Exception[%{For now this only works for sqlite strings.  Couldn't parse "#{connect_string}"}]
        end
        filename = md[1]
        filename
      end

      def db_connect
        return false if DataMapper::Repository.adapters.size > 0
        connect_string = cli.config.db[@univ.env]
        DataMapper.setup(:default, connect_string)
        require 'hipe-socialsync/model'
      end

      def before_run(univ)
        @univ = univ
        db_connect
      end

      def run(argv)
        argv.unshift(*@prepend)
        return catch(:invalid) do
          DataMapper.repository do
            cli.run(argv)
          end
        end # return either the ValidationError or the result
      end

      cli.does('ping','the minimal action') do
        option('--db','try connecting')
      end
      def ping(opts)
        out = cli.out.new
        out << 'Hello.'
        out << %{  My environment is "#{opts.env}".}
        if (opts.db)
          db_connect
          out << %{  My database file is "#{File.basename(db_path)}".}
        end
        out
      end
    end
    module ViewCommon
      include Hipe::AsciiTypesetting::Methods
      def date_format(at)
        at.strftime('%Y-%m-%d %H:%I:%S')
      end
      def humanize_lite(str)
        str.to_s.gsub('_',' ')
      end
    end
    module ControllerCommon
      def current_user(identifier)
        return identifier if identifier.kind_of? Model::User
        Hipe::SocialSync::Model::User.first_or_throw :email=>identifier
      end
      def argument_error(*args)
        throw :invalid, Model::ValidationErrors[*args]
      end
    end
  end # SocialSync
end # Hipe
