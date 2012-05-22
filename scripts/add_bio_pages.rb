require 'fileutils'

blog_directories = Dir.entries('.').reject{ |entry| entry.match(/^\.|^_/) || !File.directory?(entry) }
blog_directories.each do |blog_folder|
  Dir.chdir("#{blog_folder}") do
    File.open("index.html", "w") do |f|
        f.puts "---
name: 
short_bio: 
user_info:
  title: 
  areas_of_interest: 
  employment_date: 
  alma_mater: 
  nic_sports: 
social:
  twitter: <your twitter>
---"
      end
  end
end

