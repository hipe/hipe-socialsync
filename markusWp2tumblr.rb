#!/usr/bin/env ruby

require "rubygems"
require "hpricot"
require "yaml"
require "getopt/long"

module Markus
  class Wp2Tumblr
    attr_accessor :doc, :intermediate_file, :intermediate_filename, :re;
    
    def parse_wp_xml(args)
      self.re = /\A<!\[CDATA\[(.*)\]\]>\Z/m
      self.intermediate_filename = 'tmp.wp2tumblr.yml'
      fn = args[:input_xml_filename]
      unless (matches = /\.(xml)\Z/.match(fn)) then
        print "Sorry, expecting the file to end in *.xml.  #{fn} is an invalid filename.\n"
        return
      end
      if ! File.exist?( fn )
        print "file does not exist: "+fn+"\n"
        return
      end
      fh = open fn
      print "attempting to parse xml in "+fn+"\n";
      self.doc = Hpricot.XML(fh)
      print "parsed.\n"
      self.make_intermediate_file
    end
    
    attr_accessor :num_articles_pushed

    def tumblr_params
      if (!@tumblr_params) 
        @tumblr_params = {
          :email => {
            :desc => 'Your tumblr account\'s email address',
            :value => nil,
            :required => true
          },
          :password => {
            :desc => 'Your account\'s password',
            :value => nil,
            :required => true
          },
          :type => {
            :required => true,
            :value    => 'regular'
            #   # regular photo quote link conversation video audio           
          },
          :generator => {
            :required => false,
            :value => 'MarkusWp2tumbler version 0.01beta'
          },
          :date => {
            :required => true,
            :value => 'to be determined'
          },
          :private => {
            :type => :bool,
            :required => false,
            :value => 0,
            :desc => 'Whether the post is private. Private posts only appear in the Dashboard or with authenticated links, and do not appear on the blog\'s main page.'
          },
          :tags => {
            :desc => 'Comma-separated list of post tags. You may optionally enclose tags in double-quotes.',
            :required => false,
            :value => 'to be determined'
          },
          :format => {
            :required => false,
            :value => 'html'
          }
        }
      end
      @tumblr_params
    end 
    
    # note that here it sort of kills the point of trying to save on memory
    def push_intermediate_file(fh)
      struct = YAML::load fh
      self.get_missing_tumblr_args
      self.num_articles_pushed = 0;
      struct[:articles].each do |article|
        self.push_article_to_tumblr(article)
        print "yes:\n"+article[:content]+"\n"
      end
      puts "done pushing #{self.num_articles_pushed} articles to tumblr."
    end
    
    def push_article_to_tumblr
    end
    
    def make_intermediate_file
      self.intermediate_file = File.open(self.intermediate_filename, 'w')
      self.get_keywords
    end
    
    def truncate(str,size)
      useSize = ((size-5)/2).floor
      if str.length <= size 
        return str
      else
        # re1 = Regexp.new("\A([.\n]{1,"+useSize.to_s+"})",'m')        
        # re2 = Regexp.new("([.\n]{1,"+useSize.to_s+"})\\Z",'m')
        # m1 = re1.match(str);
        # m2 = re2.match(str);
        # str = ''
        # str << ( m1.nil? ? ("FAILED1: "+re1.to_s) : m1[1] );
        # str << '[...]'
        # str << ( m2.nil? ? ("FAILED2: "+re2.to_s) : m2[1] );
        str = str[0,useSize] + '[...]' + str[(-1*useSize)..-1]
        return str
      end
    end
    
    def unCdata(str)
      matches = self.re.match(str)
      if (! matches) 
        throw Exception.new(self.truncate("failed to match #{str} against #{self.re.to_s}\n",160))
      end
      return matches[1]
    end
    
    def get_keywords
      tagstruct = { :tags => [] }
      keyword_list = tagstruct[:tags]
      # we do it as list in tree not stream style b/c we assume the tag list will never bee too long
      (self.doc/:channel/'wp:tag').each do |tag|
        slug = (tag/'wp:tag_slug').inner_html
        name = self.unCdata((tag/'wp:tag_name').inner_html)
        keyword_list << { :name => name, :slug => slug }
      end
      yaml_obj = YAML::dump( tagstruct )
      self.intermediate_file.write( yaml_obj.to_s )
      self.get_articles
    end
    
    def get_articles
      self.intermediate_file.write(":articles:\n");
      obj = {}
      i = 0;
      (self.doc/:channel/:item).each do |item|
        obj[:status] = (item/'wp:status').inner_html
        art_id = item/'wp:post_id'
        if ! (obj[:status] == 'publish'||obj[:status]=='inherit') 
          print "skipping article (##{art_id}) with status of "+obj[:status]+"\n";
          next
        end
        obj[:content] = self.unCdata( (item/'content:encoded').inner_html )
        if (obj[:content].length == 0)
          print "skipping article (##{art_id}) with empty content (probably an uploaded attachment)\n"
        end                  
        obj[:author] = self.unCdata( (item/'dc:creator').inner_html )
        obj[:post_date] = (item/'wp:post_date').inner_html
        yaml_obj = YAML::dump( obj )
        s = yaml_obj.to_s
        s.sub!(/\A--- \n/, '');
        s = '- '+s.gsub(/\n(?!\Z)/, "\n  ");
        self.intermediate_file.write( s )
        i += 1;
      end
      print "wrote intermediate file \"#{self.intermediate_filename}\"." 
    end
    def push_to_tumblr
      print "implement me: "+(@tumblr_params[:email][:value].to_s)
    end  
  end # end backend

  class Wp2TumblrCli
    
    def initialize
      @skip = [:password, :date, :generator, :format, :date, :private, :tags, :type]
    end
    
    def show_usage
      print "Usage: "+__FILE__+" [OPTIONS] COMMAND\n"+
      "commands: \n"+
      "  parse-wp-xml WP_INPUT_XML_FILE\n"+
      "  push-to-tumblr (this runs interactively)\n"+
      "  NAMED_ARGUMENTS push-to-tumblr (try running the above first)\n"      
    end
  
    def run
      unless ( ARGV.size >= 1 ) then self.show_usage; exit; end
      @backend = Wp2Tumblr.new   
      case true
        when ('parse-wp-xml'==ARGV[0])
          unless ARGV.size >= 2 then self.show_usage; exit; end
          args = {
            :input_xml_filename => ARGV[1]
          }        
          backend.parse_wp_xml args
        when ('push-to-tumblr'==ARGV.last())
          ARGV.pop(); #throw it away b/c getopt/long is stupid
          OptionsParser.new({:options => @backend.tumblr_params}).getopts; #populates tumblr_params!
          prompted = self.get_missing_tumblr_args
          if prompted 
            generate_push_command
          else
            @backend.push_to_tumblr
          end
        else
          puts "Invalid command: "+ARGV.last()
          show_usage
      end #end case
    end #def
    
    def generate_push_command # ''todo'' move to OptionsParse
      puts "Please push to tumblr by copy-pasting this into your prompt and pressing enter:"
      print __FILE__;
      @backend.tumblr_params.each do |key,value|
        next if @skip.include? key
        if (value[:value].nil?)
          val_string = 'missing value for '+(key.to_s)
        else 
         val_string = (value[:type] == :bool) ? value[:value] : ('"'+(value[:value].gsub(/(?!<\\)"/,'\"'))+'"');
        end
        print " --"+(key.to_s)+"=#{val_string}";
      end
      print " push-to-tumblr\n";
    end
    
    # ''todo'' move to OptionsParse
    def get_missing_tumblr_args
      prompted = false;
      @backend.tumblr_params.each do |key, arg|
        next if (:password == key)
        if (arg[:value].nil?)
          prompted = true;
          print key.to_s+" ("+arg[:desc]+")"
          print " (y/n)" if (arg[:type] == :bool)
          print " (optional)" unless (arg[:required])
          print " :"
          begin
            repeat = false
            entry = gets
            entry.strip!
            if (:bool==arg[:type] && ! ['y','n'].include?(entry) )
              unless (!args[:required] && ''==entry)              
                puts "Please enter 'y' or 'n'.\"#{entry}\" is not a valid answer."
                repeat = true
              end
            elsif (arg[:required] && ''===entry)
              puts "This is a required field.  Please enter something."
              repeat = true
            else
              @backend.tumblr_params[key][:value] = entry
            end
          end while repeat
        end # if no value for arg
      end # each arg
      return prompted
    end # def
  end #cli class
  
  # this represents both a parsing grammar and the parse tree.
  class OptionsParser
    include Getopt    
    def initialize(tree)
      @options = tree[:options]
    end
    def getopts()
      optsGrammar = []
      @options.each do |key,value|
        next unless (value[:value].nil?)
        optsGrammar.push(['--'+key.to_s, nil, ::Getopt::REQUIRED])
      end
      opts = Long.getopts(optsGrammar);
      opts.each do |key,value|
        print "key: #{key} (#{key.class.to_s}) value:'#{value}'\n"        
        if (key.nil?)
          print "getopt sucks - skipping\n"          
          next
        end
        @options[key.to_sym][:value] = value
      end
    end
  end
  
end #mod 

Markus::Wp2TumblrCli.new.run
