class File
  def self.replace_extension filename, newext
      File.basename(filename, '.*') + ".#{newext}"
  end
end
