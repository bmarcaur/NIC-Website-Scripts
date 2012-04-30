# Created by Nick Gerakines, open source and publically available under the
# MIT license. Use this module at your own risk.
# Repurposed for NIC by Brandon Marc-Aurele

require 'rubygems'
require 'sequel'
require 'fileutils'
require 'yaml'

module NIC_BLOG_IMPORT
  # This query will pull blog posts from all entries across all blogs. If
  # you've got unpublished, deleted or otherwise hidden posts please sift
  # through the created posts to make sure nothing is accidently published.
  POST_QUERY = "SELECT
            mt_entry.entry_atom_id AS entry_type,
            mt_entry.entry_basename AS entry_url_name,
            mt_entry.entry_text AS text,
            mt_entry.entry_text_more AS text_more,
            mt_entry.entry_authored_on AS authored_on,
            mt_entry.entry_title AS title,
            mt_entry.entry_convert_breaks AS extension,
            GROUP_CONCAT(mt_category.category_label SEPARATOR ' ') AS tags,
            mt_author.author_nickname AS author_name
          FROM mt_entry
          INNER JOIN mt_author
            ON mt_entry.entry_author_id=mt_author.author_id
          INNER JOIN mt_placement
            ON mt_entry.entry_id=mt_placement.placement_entry_id
          INNER JOIN mt_category
            ON mt_placement.placement_category_id=mt_category.category_id
          WHERE mt_entry.entry_atom_id LIKE '%www.nearinfinity.com%'
            AND mt_entry.entry_atom_id NOT LIKE '%home%'
          GROUP BY mt_entry.entry_id
          ORDER BY mt_entry.entry_id"

  ASSET_QUERY = "SELECT
                  asset_file_path AS path,
                  asset_file_name AS name
                FROM mt_asset
                WHERE asset_file_path
                LIKE '%assets%'"

  def self.process(dbname, user, pass, host = 'localhost', requested_type)
    db = Sequel.mysql(dbname, :user => user, :password => pass, :host => host, :encoding => 'utf8')

    db[POST_QUERY].each do |post|
      # Concatinate the nickname into the MT like naming structure
      user_name = post[:author_name].downcase.split(' ').join('_')

      # Grab and parse the type of blog, i.e. blog, news, training
      entry_type = self.determine_entry_type post[:entry_type]
      next if entry_type[:url] != requested_type

      # if we cannot parse an entry type then one of our assumptions is incorrect 
      # and this needs to be fixed immediately
      if entry_type.nil?
        puts post[:title] + ' had a malformed entry type, take a look at it.'
        break
      end

      # determine the file location based on the type and the author
      file_location = (entry_type[:url] == 'blogs') ? [user_name, '_posts'].join('/') : ['_posts'].join('/')

      # Ideally, this script would determine the post format (markdown,
      # html, etc) and create files with proper extensions. At this point
      # it just assumes that markdown will be acceptable.
      date = post[:authored_on]
      jekyll_filename = post[:entry_url_name].gsub(/_/, '-')
      file_extension = self.suffix(post[:extension])
      file_name_storage = [date.year, date.month, date.day, jekyll_filename].join('-') + '.' + file_extension
      file_name_url = post[:entry_url_name]

      # full filenames
      file_storage_location = "./#{file_location}/#{file_name_storage}"
      file_permalink = "/#{entry_type[:permalink]}/#{user_name}/#{file_name_url}.html"

      # Grab the post content, be sure to append the addition text
      content = post[:text_more].nil? ? post[:text] : post[:text] + " \n" + post[:text_more]

      #if the body is blank do nothing
      next if content.nil?

      # if the body is html, mark it as raw
      if file_extension == 'html'
        content = "{% raw %}\n" + content + '{% endraw %}'
      end

      # Fix all the asset paths and move assets
      begin
        self.correct_post_assets(db, file_location, content)
      rescue
        puts "An error occured when trying to move and correct the assets for post :"
        puts post.inspect
      end

      # create the front yaml meta data
      data = {
        'permalink' => file_permalink,
        'layout' => entry_type[:url],
        'title' => post[:title].to_s,
        'date' => date,
        'tags' => post[:tags]
      }.delete_if { |k,v| v.nil? || v == '' }.to_yaml

      #create the directory for the post
      FileUtils.mkdir_p file_location

      # Write the front yaml data and then divide it and post the content
      # into the correct file name and location
      File.open(file_storage_location, "w") do |f|
        f.puts data
        f.puts "---"
        f.puts content
      end
    end
  end

  private

  def self.correct_post_assets(database, new_location, post_content)
    database[ASSET_QUERY].each do |asset|
      #determine the new asset location
      asset_location = "#{new_location}/assets/".sub(/\/\_posts/, '')

      # Make the asset folder for a user that has posts
      FileUtils.mkdir_p(asset_location)

      #substitute the new asset location into the post
      lookup_string = asset[:path].sub(/\%r/, '/blogs').sub('/\//', '\/')
      
      if !post_content.sub!(/#{lookup_string}/, "/#{asset_location + asset[:name]}").nil?
        # Move the file if it is present in this post
        FileUtils.cp asset[:path].sub(/assets/, '_blogs-assets').sub(/\%r/, '.'), asset_location
      end
    end
  end

  def self.suffix(file_extension)
    if file_extension.nil? || file_extension.include?("markdown")
      # The markdown plugin I have saves this as
      # "markdown_with_smarty_pants", so I just look for "markdown".
      "markdown"
    elsif file_extension.include?("textile")
      # This is saved as "textile_2" on my installation of MT 5.1.
      "textile"
    elsif file_extension == "0" || file_extension.include?("richtext")
      # Richtext looks to me like it's saved as HTML, so I include it here.
      "html"
    else
      # Other values might need custom work.
      file_extension
    end
  end

  # Uses the type string to return the proper sub category
  def self.determine_entry_type(type_string)
    return {:permalink => 'blogs', :url => 'blogs'} if !type_string[/blog/].nil?
    return {:permalink => 'news/news', :url => 'news'} if !type_string[/news/].nil?
    return {:permalink => 'training_center', :url => 'training_center'} if !type_string[/training/].nil?
    puts 'The entry type: ' + type_string + ' is not a valid type, something is up.'
    return nil;
  end
end

## Actually Imports
NIC_BLOG_IMPORT.process("MOVABLE_DATA", "root", "", 'blogs')
