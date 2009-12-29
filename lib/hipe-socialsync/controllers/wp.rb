# socsync wp:pull out.yml data/wordpress.rizmo.2009-11-17.xml
require 'nokogiri'           # for parsing responses from xml data from blog services
require 'yaml'               # for representing the intermediate data file
require 'hipe-core/lingual/fun-summarize'
require 'hipe-core/struct/open-struct-extended'
require 'ostruct'

module Hipe::SocialSync::Plugins
  class Wp
    include Hipe::Cli
    include Hipe::SocialSync::Model
    include Hipe::SocialSync::ControllerCommon
    cli.out.klass = Hipe::Io::GoldenHammer

    cli.does '-h','--help', 'overview of wp commands'
    cli.default_command = :help

    cli.does(:pull,'parse wordpress xml into database.') {
      option('-h',&help)
      option('-d','--dry',"Dry run.  Does everything the same but write to the database.")
      option('limit', "only this many will be pulled in from the xml file", :default=>'2'){|it|
        it.must_match(0..50)
        it.must_be_integer
      }
      required('xml-in','an xml worpress dumpfile to pull into the database.'){|it|
        it.must_match(/\.xml\z/,'It must end in *.xml')
        it.must_exist
        it.gets_opened('r')
      }
      required('service-credential-name','eg your email on the service')
      required('current-user-email','who is using this?')
    }

    def pull(xml_in, name_credential, current_user_email, opts)
      user = current_user(current_user_email)
      svc = Service.first_or_throw(:name=>'wordpress')
      acct = Account.first_or_throw(:user=>user,:service=>svc,:name_credential=>name_credential)
      @limit = opts.limit
      @out = cli.out.new
      @summary = {
        :skipped => {
          :because_of_status => {},
          :because_of_no_content => 0 },
        :pulled_reflection_of => 0,
        :number_of_files_parsed => 0,
      }
      objects = parse_xml xml_in
      return @out unless @out.valid?
      @out << summarize(@summary)
      item_controller  = cli.parent.plugins[:items]
      i = nil
      objects.each_with_index do |o,i|
        sub_out = item_controller.cli.run(['add',
          'wordpress', name_credential, o.art_id,
          o.author, o.content, o.tags,
          o.post_date, o.status, o.title,
          current_user_email
        ])
        return sub_out unless sub_out.valid?
        @out.puts sub_out.to_s
      end
      @out.puts %{\nDone importing #{i} objects.}
      @out
    end

    def parse_xml file
      objects = []
      use_filename = File.basename(file.path)
      summary = @summary
      @out << %{\n\n#{'='*20} #{use_filename} #{'='*20}\n}
      begin
        # wordpress dumps are of course not valid xml.  they breakup the rss tag across multiple lines
        doc = Nokogiri::XML(file ,nil,nil,Nokogiri::XML::ParseOptions::RECOVER) # was STRICT
      rescue Nokogiri::XML::SyntaxError => e
        @out.errors << %{ERROR: failed to parse "#{use_filename}" as well-formed XML! }+
        %{skipping file. Error: "#{e.message.strip}"}
        return false
      end
      summary[:number_of_files_parsed] += 1
      summarizer = Hipe::FunSummarize
      limit_reached = false
      doc.xpath('/rss/channel/item').each do |item_node|
        obj = object_from_nokogiri_node item_node
        if ! (['publish','inherit','draft'].include?(obj.status))
          @out.puts summarizer.minimize(%q{Skipping article #%%id%% because of status "%%status %%"},
          "id" => obj.art_id,"status "=>obj.status)
          summary[:skipped][:because_of_status][obj.status.to_sym] ||= 0
          summary[:skipped][:because_of_status][obj.status.to_sym] += 1
        elsif (obj.content.length == 0)
          @out.puts summarizer.minimize(
            %{\nSkipping article #%%#%% with empty content (probably an uploaded attachment)},
            '#' => obj.art_id
          )
          summary[:skipped][:because_of_no_content] += 1
        else
          @out.puts summarizer.minimize(%{\nGrabbing article #%%id%%},'_id_' => obj.art_id)
          summary[:pulled_reflection_of] += 1
          objects << OpenStruct.new(obj)
          if (@limit && summary[:pulled_reflection_of] >= @limit)
            @out.puts %{\nReached limit of #{@limit} items.}
            limit_reached = true
            break
          end
        end
      end # each nokogiri item node
      objects
    end # def objects_file

    def object_from_nokogiri_node node
      obj = Hipe::OpenStructExtended.new
      obj.title       = node.at_xpath('./title').content
      obj.status      = node.at_xpath('./wp:status').content
      obj.art_id      = node.at_xpath('./wp:post_id').content
      obj.content     = node.at_xpath('./content:encoded').content
      obj.author      = node.at_xpath('./dc:creator').content
      obj.post_date   = node.at_xpath('./wp:post_date').content
      obj.tags = []
      node.xpath('./category[@domain="tag" and @nicename]').each do |cat|
      obj.tags << cat.content
      end
      obj.tags = obj.tags * ','
      obj
    end

    def summarize summary
      s = ''
      s << ( "\n\n"+((('='*80)+"\n")*1)+"\nSummary: \n" )
      s << "of items in wordpress xml "+ Hipe::FunSummarize.summarize_totals(summary);
      s << "\n"
      s
    end
  end # end wordpress
end
