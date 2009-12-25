#!/usr/bin/env ruby
require 'rubygems'
require 'ruby-debug'
require 'hipe-cli'
require 'hipe-core/infrastructure/exception-like'
require 'hipe-core/struct/open-struct-extended'
require 'hipe-core/logic/rules-lite'
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
      def self.upgrade(exception)
        return if exception.respond_to? :valid?
        exception.extend ExceptionUpgrage
        exception
      end
      def valid?; false end
    end
   #class SoftException < Exception
   #  alias_method :orig_to_s, :to_s
   #  def to_s
   #    msg = orig_to_s
   #    if (['',nil,self.class.to_s].include?(msg) and @details[:object])
   #      msg =  (@details[:object].errors.map.flatten.join('  '))
   #    end
   #    msg
   #  end                
   #end
   #
   ## Should the user see the message from the exception? 
   #KindOfRe = %r{^\+([^\+]+)\+ should be Hipe::SocialSync::Model::([^,]+), but was (.+)}
   #Gracefuls = Hipe::RulesLite.new do
   #  rule( "SoftExceptions can be shown to the user"){
   #    condition  { SoftException === e }
   #    consequence{ e }
   #  }
   #  rule( "type assertion failures can be shown to user" ){
   #    condition   { ArgumentError === e && (response.md = KindOfRe.match(e.message)) }
   #    consequence { SoftException[%{#{response.md[1]} #{response.md[2].downcase} not found}] }
   #  }
   #end
    class App
      include Hipe::Cli
      cli.program_name = 'sosy' # necessary b/c when running it from bacon, its name became 'bacon'
      cli.description = 'Import your wordpress blogs into tumblr.'      
      cli.option('-e','--env ENV',['test','dev'],'environment', :default=>'dev')
      cli.does '-h','--help' , 'display this help screen (for the sosy app)'
      cli.default_command = :help
      cli.plugins.add_directory(%{#{DIR}/lib/hipe-socialsync/controllers}, Plugins, :lazy=>true)
      #cli.graceful{ |e| Gracefuls.assess(:e=>e, :response=>OpenStruct.new) }
      cli.config = OpenStruct.new({
        :db => Hipe::OpenStructExtended.new({
          :test => %{sqlite3://#{Hipe::SocialSync::DIR}/data/test.db},
          :dev  => %{sqlite3://#{Hipe::SocialSync::DIR}/data/dev.db}
        })
      })
      
      def connect!
        unless (connect_string = cli.config.db[cli.opts.env])
          raise Exception[%{Couldn't find connect string for evironment setting #{cli.opts.env.inspect}}]
        end
        DataMapper.setup(:default, connect_string)
      end

      # @return [bool] whether or not you actually needed to make a db connection
      def before_run
        return false if DataMapper::Repository.adapters.size > 0
        connect!
        require 'hipe-socialsync/model'
        true
      end
      
      def run(argv)
        return catch(:invalid) { cli.run(argv) } # return either the ValidationError or the result
      end
      
      cli.does('db-rotate', 'move the dev database over') do
        option('-c','--consistent','output the same thing every time (for gulp testing)')
      end
      def db_rotate(opts)
        connect_string = cli.config.db[opts.env]
        unless(md=%r{^sqlite3://(.*)$}.match(connect_string))
          raise Exception[%{db_rotate only works for sqlite strings.  couldn't parse "#{connect_string}"}]
        end
        filename = md[1]
        begin
          if (File.exists?(filename))
            backup = %{#{filename}.#{DateTime.now.strftime('%Y-%m-%d__%H_%I_%S.db')}}
            FileUtils.mv(filename,backup)
            result = opts.consistent ?  
              %{moved #{File.basename(filename)} to backup file.} : 
              %{moved #{filename} to #{backup}} 
            connect!
          else 
            result = %{file #{filename} doesn't exist}
          end
        rescue Errno::ENOENT => e
          result = Exception.upgrade(e)
        end
        Hipe::Io::GoldenHammer[result]
      end
    end
  end
end
