<?php
/*
Plugin Name: Wp2Tumblr
Plugin URI: http://fushji.netsons.org/?page_id=9
Description: Publish on Tumblr your post
Author: Antonio Perrone <fUsHji>
Author URI: http://fushji.netsons.org
*/


function wp2tumblr_admin_menu()
{
  add_options_page('Wp2Tumblr options', 'Wp2Tumblr', 10, __FILE__, 'wp2tumblr_options_page');
}

function wp2tumblr_install()
{
	add_option('tumblr_user','username');
	add_option('tumblr_pass','password');
}

function wp2tumblr_options_page()
{
 		$username = get_option( 'tumblr_user');
		$password = get_option( 'tumblr_pass');
	
    	
    	if( $_POST['update'] == 'Y' ) {		
        	update_option('tumblr_user',$_POST['tumblr_username']);
        	update_option('tumblr_pass',$_POST['tumblr_password']);
			if ($_POST['default_check'])
				update_option('tumblr_default','Y');
			else
				update_option('tumblr_default','N');				
           	echo '<div id="message" class="updated fade"><p><strong>Tumblr options saved</strong></p></div>';
   		 }


	echo '<div class="wrap">';
	echo '<h2>Wp2Tumblr options page</h2>';
	echo '<h3>Tumblr account:</h3>';
	echo '<form id="tumblr_account_form" name="tumblr_account_form" method="post" action="">
		<input type="hidden" name="update" value="Y">	
  <label>Username
  <input type="text" name="tumblr_username" id="tumblr_username" value="'.$username.'"/>
  </label>
  <p>
    <label>Password
    <input type="password" name="tumblr_password" id="tumblr_password" value="'.$password.'"/>
    </label>
  </p>
  <p>
	<label>
  	<input type="checkbox" name="default_check" id="default_check" /> Yes, check as default.</label>
  </p>
  <p>
    <label>
    <input type="submit" name="submit" id="submit" value="Update options >>" />
    </label>
  </p>
</form> </div>';
}

function wp2tumblr_form()
{
	global $wpdb, $post_ID;
	
	echo '<h3 class="dbx-handle">Wp2Tumblr</h3>';
	echo '<div class="dbx-content">';
	if ((get_option( 'tumblr_user') == 'username') || (get_option( 'tumblr_user') == '') ||(get_option( 'tumblr_pass') == 'password') || (get_option( 'tumblr_pass') == '')){
	
	 echo '<p>You have not yet entered a Tumblr username or password. You must enter this information in the <a href="';
    bloginfo('wpurl');
    echo '/wp-admin/options-general.php?page=wp2tumblr.php">options page</a> before you can use Wp2Tumblr.</p>' . "\n";
	
	}else {
		
		if (get_option( 'tumblr_default') == 'N')
		 echo '<p style="line-height: 1.2em; margin-top: .5em; margin-bottom: 0;"><input type="checkbox" name="wp2tumblr_checkbox" id="wp2tumblr_checkbox"> Post to Tumblr</p>';
		else
		 echo '<p style="line-height: 1.2em; margin-top: .5em; margin-bottom: 0;"><input type="checkbox" name="wp2tumblr_checkbox" id="wp2tumblr_checkbox" checked="checked"> Post to Tumblr</p>';
	}
	
	echo '</div>';
}

function wp2tumblr_submit($post_ID)
{
	global $wpdb;
	
	if ($_POST['wp2tumblr_checkbox']) {
		$last_post = $wpdb->get_row("SELECT * FROM $wpdb->posts WHERE ID = '$post_ID'");
		$post_body = $last_post->post_content;
		$post_title = $last_post->post_title;	

		$post_type  = 'regular';

		
		$request_data = http_build_query(
    		array(
        		'email'     => get_option('tumblr_user'),
        		'password'  => get_option( 'tumblr_pass'),
        		'type'      => $post_type,
        		'title'     => $post_title,
        		'body'      => $post_body,
        		'generator' => 'Wp2Tumblr plugin'
    		)
		);

		
		$handle = curl_init('http://www.tumblr.com/api/write');
		curl_setopt($handle, CURLOPT_POST, true);
		curl_setopt($handle, CURLOPT_POSTFIELDS, $request_data);
		curl_setopt($handle, CURLOPT_RETURNTRANSFER, true);
		$result = curl_exec($handle);
		curl_close($handle);
	}
}

add_action('activate_wp2tumblr.php', 'wp2tumblr_install');
add_action('simple_edit_form', 'wp2tumblr_form', 1);
add_action('edit_form_advanced', 'wp2tumblr_form', 1);
add_action('publish_post', 'wp2tumblr_submit');
add_action('admin_menu', 'wp2tumblr_admin_menu');

?>
