desc 'Creates po files'
task :po do
  require 'gettext/utils'
  GetText.update_pofiles("rubycas-server", Dir.glob("{lib,bin}/**/*.{rb}"), "rubycas-server ")
end

desc 'Creates mo files from po files and puts them to locale dir'
task :mo do
  require 'gettext/utils'
  GetText.create_mofiles(true, "po", "locale") 
end
