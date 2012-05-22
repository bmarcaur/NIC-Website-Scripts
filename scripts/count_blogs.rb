require 'fileutils'

blog_directories = Dir.entries('.').reject{ |entry| entry.match(/^\./) || !File.directory?(entry) }
blog_directories.each do |blog_folder|
  Dir.chdir("#{blog_folder}/_posts") do
    puts blog_folder
    puts Dir.entries('.').reject{ |entry| entry.match(/^\./) }.count
  end
end