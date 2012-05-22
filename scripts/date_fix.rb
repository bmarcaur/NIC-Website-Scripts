require 'fileutils'

blog_directories = Dir.entries('.').reject{ |entry| entry.match(/^\./) || !File.directory?(entry) }
blog_directories.each do |blog_folder|
  Dir.chdir("#{blog_folder}/_posts") do
    Dir.entries('.').reject{ |entry| entry.match(/^\./) }.each do |post|
      puts blog_folder
      puts post
      newNamePieces = post.split('-')
      newNamePieces[1] = "%02d" % newNamePieces[1] unless newNamePieces[1].length > 1
      newNamePieces[2] = "%02d" % newNamePieces[2] unless newNamePieces[2].length > 1
      FileUtils.mv post, newNamePieces.join('-') unless post == newNamePieces.join('-')
    end
  end
end