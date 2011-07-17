require 'date'
require 'find'

spec = Gem::Specification.new do |s|
  s.name = 'gtk2diaryapp'
  s.version = `gtk2diaryapp -v`.strip
  s.date = Date.today.to_s
  s.summary = 'Ruby-Gtk2 Diary'
  s.email = 'carlosjhr64@gmail.com'
  s.homepage = 'https://sites.google.com/site/gtk2applib/home/gtk2applib-applications/gtk2diary'
  s.description = <<EOT
A Ruby-Gtk2 Diary
EOT
  s.has_rdoc = false
  s.authors = ['carlosjhr64@gmail.com']

  files = []
  # Rbs
  Find.find('.'){|fn|
    if fn=~/\.rb$/ then
      files.push(fn)
    end
  }

  files.concat( [
	# Gifs
	'pngs/logo.png',
	'pngs/icon.png',
	# README
	'README.txt'
	] )

  s.files = files

  s.executables = [
	'gtk2diaryapp',
	]

  s.default_executable = 'gtk2diaryapp'

  s.add_dependency('gtk2applib', '~> 15.3')
  s.requirements << 'gtk2'

  #s.rubyforge_project = 'gtk2diaryapp'
end
