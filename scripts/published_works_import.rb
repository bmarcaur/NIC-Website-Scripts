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
  POST_QUERY =
  "
    SELECT
      mt_entry.entry_atom_id AS entry_type,
      mt_entry.entry_basename AS entry_url_name,
      mt_entry.entry_text AS text,
      mt_entry.entry_text_more AS text_more,
      mt_entry.entry_authored_on AS authored_on,
      mt_entry.entry_title AS title,
      mt_entry.entry_convert_breaks AS extension
    FROM mt_category
    LEFT JOIN mt_placement
      ON mt_category.category_id = mt_placement.placement_category_id
    LEFT JOIN mt_entry
      ON mt_placement.placement_entry_id=mt_entry.entry_id
    where mt_category.category_basename = 'published_works'
    GROUP BY mt_entry.entry_id
    ORDER BY mt_entry.entry_id;
  "

  def self.process(dbname, user, pass, host = 'localhost')
    db = Sequel.mysql(dbname, :user => user, :password => pass, :host => host, :encoding => 'utf8')

    db[POST_QUERY].each do |post|
      puts post.inspect
      # determine the file location based on the type and the author
      file_location = '/published_works/_posts'

      # Ideally, this script would determine the post format (markdown,
      # html, etc) and create files with proper extensions. At this point
      # it just assumes that markdown will be acceptable.
      date = post[:authored_on]
      jekyll_filename = post[:entry_url_name].gsub(/_/, '-')
      file_extension = self.suffix(post[:extension])
      file_name_storage = [date.year, "%02d" % date.month, "%02d" % date.day, jekyll_filename].join('-') + '.' + file_extension
      file_name_url = post[:entry_url_name]

      # full filenames
      file_storage_location = "./#{file_location}/#{file_name_storage}"
      file_permalink = "/news/published_works/#{file_name_url}.html"

      # Grab the post content, be sure to append the addition text
      content = post[:text_more].nil? ? post[:text] : post[:text] + " \n" + post[:text_more]

      #if the body is blank do nothing
      next if content.nil?

      # if the body is html, mark it as raw
      if file_extension == 'html'
        content = "{% raw %}\n" + content + '{% endraw %}'
      end

      # create the front yaml meta data
      data = {
        'permalink' => file_permalink,
        'layout' => entry_type[:url],
        'title' => post[:title].to_s,
        'date' => date,
        'tags' => post[:tags] || ''
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
end

## Actually Imports
NIC_BLOG_IMPORT.process("MOVABLE_DATA", "root", "")