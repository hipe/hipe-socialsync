# require 'highline/import'    # for password prompting
require 'hipe-socialsync/transport/tumblr-transport'
module Hipe::SocialSync::Plugins
  class Tumblr
    include Hipe::Cli
    include Hipe::SocialSync::Model
    include Hipe::SocialSync::ViewCommon
    include Hipe::SocialSync::ControllerCommon
    ItemModel = Hipe::SocialSync::Model::Item

    cli.out.klass = Hipe::SocialSync::GoldenHammer
    cli.does 'help','overview of item commands'
    cli.description = "blog entries"
    cli.default_command = :help

    cli.does('push',"push the item(s) to tumblr") do
      option('-h',&help)
      option('--sleep-every SEC',  "sleep for n seconds after you push these many items", :default=>'2') do |it|
        it.must_match_range(0..60).must_be_integer
      end
      option('--sleep-for SEC', "sleep for this many seconds after each n items you push", :default=>'2') do |it|
        it.must_match_range(0..600)
      end
      option('-d', '--dry', "Don't actually push these up, just show a preview of what you would do.")
      required('ids', 'comma-separated list of ids to push') do |it|
        it.must_match(/^(\d+(?:,\d+)*)$/)
      end
      required 'tumblr_password', 'the password for the account these ids belong to'
      required 'current_user_email'
    end

    def push ids, tumblr_password, current_user_email, opts
      ids = ids[0]
      ids_arr = ids.split(',').uniq
      user = current_user current_user_email
      ids_arr = ids.split(',').map{|x| x.to_i}.uniq
      items = ItemModel.all :id => ids_arr
      svc = Service.first_or_throw :name => 'tumblr'
      if (items.size == 0)
        return cli.out.new("Couldn't find any blog(s) with id(s): #{ids.inspect}")
      end
      items_wo_accts     = {}
      items_w_mult_accts = {}
      items.each do |item|
        accts = item.target_accounts.select{|x| x.account.service == svc }.map{|x| x.account.service }
        case accts.size
          when 0: items_wo_accts[item.id] = item
          when 1: #! ok
          else   items_w_mult_accts[item.id] = item
        end
      end
      out = cli.out.new
      out.data.responses_for_item_id = {}
      if items_w_mult_accts.size > 0
        out.errors << ("For now we can't handle pushing items that point to more than one tumblr account " <<
        %{(item id(s): (#{items_w_mult_accts.map{|x| x.id}.sort.join(',')}))} )
      end
      if items_wo_accts.size > 0
        the_ids = items_wo_accts.values.map{|x| x.id}.sort
        x = <<-HERE.gsub(/^        |\n/,'').strip
        For now items to push must explicitly have target accounts.  Please add a tumblr account as a target to
        HERE
        y = en{np(:the, 'item', pp('with', np(:the, 'id', the_ids.size, :say_count=>false)), the_ids )}.say
        out.errors << %{#{x} #{y}}
      end
      acct = items.first.target_accounts.detect{|x| x.account.service = svc }
      if (acct && acct.account.user != user)
        out2 = cli.out.new
        out2.errors << "account(s) of item(s) doesn't/don't belong to you"
        return out2
      end
      return out unless out.valid?
      actually_push_these items, acct.account, tumblr_password, user, opts
    end
    def actually_push_these items, acct, tumblr_password, user, opts
      result = cli.out.new
      transport = cli.parent.application.transports[:tumblr]
      transport.name_credential = acct.name_credential
      transport.password = tumblr_password
      transport.username = acct.name_credential
      items.each do |item|
        transport.response = nil
        transport.item_id_internal = item.id
        transport.item_title = item.title
        transport.item_body = item.content
        transport.item_date = item.published_at.to_s
        transport.item_tags = item.keywords
        sub_result = transport.push
        sub_result.data.original_item = item
        sub_result.data.original_account = acct
        after_push(sub_result,user)
        result.merge! sub_result
        return result unless result.valid?
      end
      result
    end
    # @return nil   (alter original response object)
    def after_push(sub_out,user)
      if (!sub_out.valid?)
        sub_out.errors << "Won't try to create a tumblr blog entry reflection after a failed push."
        return sub_out
      end
      if (!sub_out.data.tumblr_response)
        sub_out.errors << "Couldn't find data.tumblr_response";
        return sub_out
      end
      tumblr_item_id = sub_out.data.tumblr_response
      if (/^\d+$/ =~ tumblr_item_id)
        sub_out.data.tumblr_item_id = tumblr_item_id
      else
        sub_out.errors << "Tumblr response did not appear to be an item id: #{tumblr_id.inspect}"
        return sub_out
      end

      orig_item = sub_out.data.original_item
      orig_acct = sub_out.data.original_account

      sub_opts = Hipe::OpenStructExtended.new
      sub_opts.source = orig_item
      validation_errors = catch(:invalid) do
        new_item = Item.kreate(orig_acct, tumblr_item_id, '(author)',
          '(content)', '(keywords)', '1970-01-01',
          'status: empty reflection', '(title)', user, sub_opts)
        sub_out << %{Added empty reflection of tumblr blog (ours: ##{new_item.id}, theirs: ##{tumblr_item_id}).}
        sub_out.data.new_local_item = new_item
        nil
      end
      if validation_errors
        sub_out.errors << validation_errors.to_s
      end
      nil
    end
  end
end
