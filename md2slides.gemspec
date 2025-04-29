Gem::Specification.new do |s|
	s.name		= "md2slides"
	s.version	= "0.0.1"
	s.executables	<< "md2slides"
	s.summary	= "Markdown to presentation slides in ruby"
	s.description	= "Generate Google slides and its video file from a markdown file"
	s.authors	= [ "Motoyuki OHMORI" ]
	s.email		= "ohmori@tottori-u.ac.jp"
	s.files		= [ "lib/md2slides.rb", "lib/md2slides/md.rb", "lib/md2sdlies/presentation.rb",
			    "lib/text_to_speech.rb", "lib/audio.rb", "lib/video.rb", ]
	s.homepage	= "https://github.com/ohmori7/md2slides"
	s.license	= "MIT"
end
