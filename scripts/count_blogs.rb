require 'fileutils'

blog_directories = Dir.entries('.').reject{ |entry| entry.match(/^\.|^_/) || !File.directory?(entry) }
blog_directories.each do |blog_folder|
  Dir.chdir("#{blog_folder}/_posts") do
    count = Dir.entries('.').reject{ |entry| entry.match(/^\./) }.count
    puts "#{blog_folder}: #{count}"
  end
end