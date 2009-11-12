#!/usr/bin/env ruby

require 'rubygems'
require File.dirname(__FILE__)+'/markus/cli'
require File.dirname(__FILE__)+'/markus/structdiff'
#require 'hpricot'            # may be not being used anymore. old way to parse xml 
require 'nokogiri'           # for parsing responses from xml data from blog services
require 'yaml'               # for representing the intermediate data file
require 'rest_client'        # for pushing to blog services
require 'highline/import'    # for password prompting

module Markus

  class Wp3Tumblr    

    include Cli::App

    CDATA_RE = /\A<!\[CDATA\[(.*)\]\]>\Z/m    
    VERSION = '0.01-beta'

    def initialize
      cli_pre_init
      @intermediate_filename = 'tmp.wp2tumblr.yml'
      @date_range = nil
      @cli_description = "Import your wordpress blogs into tumblr."
      @cli_commands[:help]        = @@cli_common_commands[:help]
      @cli_global_options[:debug] = @@cli_common_options[:debug]
      @cli_commands[:parse_wp_xml] = {
        :description => 'parse wordpress xml into an intermediate yml file.',
        :splat => {
          :name => :XML_IN,
          :minimum => 1,
          :description => 'a file or fileglob name of wordpress XML dump files to take in.',
          :validations => [
            {:type=>:file_must_exist},
            {:type=>:regexp, :regexp=>/\.xml\Z/,
             :message=>"Sorry, expecting the file or fileglob to end in *.xml."
            }
          ],
          # :action => {:action=>:open_hpricot}
        }
      }
      datetime = '\d\d(?:\d\d)?-\d\d?-\d\d?(?: \d\d?)?(?::\d\d?){0,2}'
      @cli_commands[:post_to_tumblr] = {
        :description => "push the intermediate yml file up to tumblr",
        :required_arguments => [
          {:name=>:TUMBLR_ACCOUNT_EMAIL, :description=>'the email address of your tumblr account'}
        ],
        :options => {
          :date_range => {
            :description => %{The range of dates of the blogs you want to push, e.g. }+
            %{"--date-range='2010-01-01 10:10 - 2010-02-01 5:55:55'".  (note that the spaces around the middle }+
            %{are important. and a date like "2001-02-03" (with no time) actually means midnight of the previous day.},
            :validations => [{:type=>:regexp, :regexp=>%r{^(#{datetime}) - (#{datetime})},:message=>"see description"}]
          }
        }
      } # end command push to tumblr
    end # end initialize

    def tumblr_generator_name
      return File.basename(__FILE__)+' version '+VERSION
    end

    def cli_activate_opt_or_arg_open_hpricot action, var_hash, var_name
      cli_activate_opt_or_arg_open_file({:as=>'r'}, var_hash, var_name)
      @cli_files[var_name][:fh] = Hpricot(cli_file(var_name)) # overwrite
    end

    def cli_execute_parse_wp_xml
      File.open(@intermediate_filename,'w') do |fh|
        @intermediate_file = fh
        _get_articles
      end
    end
    
    def _describe_date_range
      "between "+@date_rangep[0]+" and "+@date_range[1]
    end
    
    # note that here it sort of kills the point of trying to save on memory
    def cli_execute_post_to_tumblr
      fh = File.open(@intermediate_filename, 'r')
      struct = YAML::load fh
      if (false===struct)
        raise CliFailure(%{failed to parse "@intermediate_filename" as YAML!})
      end
      question = "Please enter your tumblr account password for #{@cli_arguments[:TUMBLR_ACCOUNT_EMAIL]}: ";
      # @password = ask(question) { |q| q.echo = '*' }      
      puts %{Entered your password already here #{File.basename(__FILE__)} #{__LINE__}}
      @password = 'mmmmmmmm'
      @num_articles_pushed = 0      
      begin     
        struct[:articles].each do |article|
          if (@date_range)
            article_datetime = DateTime.parse(article[:post_date])
            if article_datetime < @date_range[0] || article_datetime > @date_range[1]
              next        
            end
          end
          post_data = _make_post_data article
          if post_data[:body].empty?
            puts %{skipping article with empty body from #{post_data[:date]} ...}
            next
          end
          _push_article_to_tumblr post_data
        end
      rescue SocketError => e
        puts %{Got a socket error: "#{e.message}" -- Is your internet on?  Do you *have* the Internet?}
        exit
      rescue RestClient::RequestFailed => e
        puts %{Couldn't connect to "#{@last_url}".  Resouce Not Found! ("#{e.message}") -- are you sure you're connected to the internet? }
        exit
      rescue RestClient::RequestFailed => e
        print %{Failed to push blog entry to target site! Got an exception of type "#{e.class}" }+
        %{that says: "#{e.message}".  We got this response body: "#{e.response.body}".\n\n}+
        %{We tried to push this blog entry: }
        puts "Failed! --\n\n"
        @post_data = @post_data.clone
        @post_data[:body] = truncate(@post_data[:body],60)        
        pp @post_data, str = ''; print str
        puts "\n\nAnd that's the end of the error.\n"
        exit
      end
      puts "done pushing #{@num_articles_pushed} articles to tumblr."            
    end
    
    def _make_post_data article
      @post_data = {
        :title =>       article[:title],
        :body =>        article[:content],
        :email =>       @cli_arguments[:TUMBLR_ACCOUNT_EMAIL],
        :password =>    @password,
        :type =>        'regular',
        :generator =>   tumblr_generator_name,
        :date =>        article[:post_date],
        :private =>     0,
        #:tags =>        '"test tag 1","testTag2","tag3"',
        :format =>      'html'  # html | markdown        
      }
    end
    
    def _push_article_to_tumblr post_data
      # http://www.tumblr.com/docs/api#api_write
      @post_date_str = post_data[:date]      
      print %{attempting to post article from #{@post_date_str} ...}
      @last_url = 'http://www.tumblr.com/api/write'
      resp = RestClient.post(@last_url, post_data) #throws on fail
      @num_articles_pushed += 1
      print "..done.\n"
    end
    
    def cli_process_option_date_range(given_opts, k)
      md = given_opts[k]
      @date_range = [
        DateTime.parse(md[1]),
        DateTime.parse(md[2])
      ]
    end
    
    # say as little of a sentence as you need to.
    #* ''extraction candidate''
    def minimize template, values
      @last_template ||= nil
      @last_values ||= nil
      if (template == @last_template)
        # they will alwyas have the same keys, so we look at middle        
        diff = StructDiff::diff(@last_values, values) 
        @last_values = values
        ret = " and "+(diff.middle_diff.map do |key,value|
          value_string = value.right.to_s.match(/^[0-9]+$/) ? value.right.to_s : %{"#{value.right}"}          
          %{#{key}#{value_string}} 
        end * " with ")
      else
        @last_template = template
        @last_values = values
        ret = "\n" + template_render( template, values )
      end
      ret
    end
    
    #* ''extraction candidate
    def template_render template, values
      ret = template.clone #* ''TODO'' test if this is necessary
      values.each{|k,v| ret.gsub! %{%%#{k}%%}, v}
      ret
    end
    
    def _get_articles
      @summary_info = {
        :skipped => {
          :because_of_status => {},
          :because_of_no_content => 0 },
        :grabbed => 0,
        :number_of_files => 0
      }
      @intermediate_file.write(":articles:\n");
      filenames = @cli_arguments[:XML_IN] #Dir[@cli_arguments[:XML_IN]]
      filenames.each do |filename|
        _get_articles_from_filename filename
      end
      print_summary_info      
    end
    
    def print_summary_info
      print( "\n\n"+((('='*80)+"\n")*1)+"\nSummary: wrote intermediate file \"#{@intermediate_filename}\" with:\n" )
      print "of items in wordpress xml "+ fun_summarize(@summary_info);
      print "\n"      
    end
    
    def _get_articles_from_filename filename
      print( %{\n\n#{'='*20} #{Cli::App.truncate(filename,38)} #{'='*20}\n} )      
      raise CliFailure(%{File must exist: "#{filename}"}) unless File.exist?(filename)
      doc = nil
      begin
        # doc = Hpricot(filename)       
        File.open(filename) do |fh|
          doc = Nokogiri::XML(fh ,nil,nil,Nokogiri::XML::ParseOptions::STRICT)
        end
      rescue Nokogiri::XML::SyntaxError => e
        puts %{EROOR: failed to parse "#{filename}" as well-formed XML!  skipping file. Error: "#{e.message.strip}"}
        return
      end
      @summary_info[:number_of_files] += 1
      # doc.search('/rss/channel/item').each do |item|  if hpricot
      doc.xpath('/rss/channel/item').each do |item_node|
        obj = nokogiri_get_item_info item_node #obj = hpricot_get_item_info(item_node)
        if ! (['publish','inherit'].include?(obj[:status])) 
          print minimize(%q{Skipping article #%%#%% because of status "%%status %%"},
            "#" => obj[:art_id],"status "=>obj[:status])
          @summary_info[:skipped][:because_of_status][obj[:status].to_sym] ||= 0
          @summary_info[:skipped][:because_of_status][obj[:status].to_sym] += 1                  
        elsif (obj[:content].length == 0)
          print minimize(%{\nSkipping article #%%#%% with empty content (probably an uploaded attachment)},
            '#' => obj[:art_id])
          @summary_info[:skipped][:because_of_no_content] += 1
        else
          print minimize(%{\nGrabbing article #%%#%%},'#' => obj[:art_id])
          @summary_info[:grabbed] += 1          
          yaml_obj = YAML::dump obj
          s = yaml_obj.to_s # in order to take this yaml dump and put it inside of another yaml tree...
          s.sub!(/\A--- \n/, ''); # remove this thing from the beginning of the yaml dump..
          s = '- '+s.gsub(/\n(?!\Z)/, "\n  ") # and indent appropriately 
          @intermediate_file.write( s )
        end
      end # each item
    end # def _get_articles  
    
    def nokogiri_get_item_info(node)
      obj = {}
      obj[:title]       = node.at_xpath('./title').content
      obj[:status]      = node.at_xpath('./wp:status').content
      obj[:art_id]      = node.at_xpath('./wp:post_id').content
      obj[:content]     = node.at_xpath('./content:encoded').content
      obj[:author]      = node.at_xpath('./dc:creator').content
      obj[:post_date]   = node.at_xpath('./wp:post_date').content
      obj[:tags] = []
      node.xpath('./category[@domain="tag" and @nicename]').each do |cat|
        obj[:tags] << cat.content
      end
      obj[:tags] = obj[:tags] * ',' # meh for readability
      obj
    end
    
    def hpricot_get_item_info(node)
      raise Exception.new("now we need to implement tags for this puppy if we ever use it")
      obj = {}
      obj[:title]       = node.at('title').inner_html      
      obj[:status]      = node.at('wp:status').inner_html
      obj[:art_id]      = node.at('wp:post_id').inner_html
      obj[:content]     = unescape_cdata( (node/'content:encoded').inner_html )
      obj[:author]      = unescape_cdata( (node/'dc:creator').inner_html )
      obj[:post_date]   = (node/'wp:post_date').inner_html
      obj
    end  
    
    # expects an arbirarily deep nested hash with symbol names and values that are either
    # (leave node) an integer or (tree node) another such hash.  returns an array of lines indented appropiratel
    def _fun_summarize(hash, indent_amt='  ', current_indent='', parent_key = nil)
      my_total = 0;
      my_lines = []      
      hash.each do |key,value|
        left_side = ([parent_key.to_s,key.to_s].compact * '_').gsub!(/_/, ' ')
        if (value.instance_of? Fixnum)
          my_lines << %{#{current_indent}#{left_side}: #{value}}
          my_total += value
        else
          child_lines,child_total = _fun_summarize(value, indent_amt, current_indent+indent_amt, key)
          my_lines << %{#{current_indent}#{left_side} (#{child_total} total):}
          my_total += child_total          
          my_lines += child_lines
        end
      end
      [my_lines, my_total]
    end
    
    def fun_summarize(hash, indent_amt='  ')
      lines, total = _fun_summarize(hash, indent_amt, current_indent='  ')
      %{(#{total} total):\n}+(lines * "\n")
    end

    def unescape_cdata str
      matches = CDATA_RE.match(str)
      unless matches
        throw Exception.new(self.truncate("failed to match #{str} against #{self.re.to_s}\n",160))
      end
      return matches[1]
    end # def unescape_cdata
  end # class Wp3Tumblr
end # module Markus
Markus::Wp3Tumblr.new.cli_run if $PROGRAM_NAME == __FILE__