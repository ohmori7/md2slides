class Presentation
	# XXX: Google Text to Speech produces at this rate...
	AUDIO_RATE = 24000

	def generate_audio0(i, notes, dir)
		print "slide \##{i}: generating audio... "
		path = __data_slide_path(i, '.m4a', dir)
		if notes
			opath = __data_slide_path(i, '.mp3', dir)
			opath = Presentation::text_to_speech(notes, opath)
			#
			# convert to .m4a, which contains duration in meta data.
			# this prevents unreasonable audio duration when combining
			# audio and video.
			#
			heading_silence = 2
			trailing_silence = 1
			cmd = <<~CMD
				ffmpeg -hide_banner -y				\
				    -f lavfi -t #{heading_silence}		\
				    -i anullsrc=r=#{AUDIO_RATE}:cl=mono		\
				    -i #{opath}					\
				    -f lavfi -t #{trailing_silence}		\
				    -i anullsrc=r=#{AUDIO_RATE}:cl=mono		\
				    -filter_complex "[0:a][1:a][2:a]concat=n=3:v=0:a=1[out]"	\
				    -map "[out]"				\
				    -c:a aac -b:a 64k #{path}
			CMD
			msg, errmsg, status = Open3.capture3(cmd)
			File.delete(opath) rescue
			if ! status.success?
				raise("ERROR: cannot convert audio: #{errmsg}")
			end
			puts 'done'
		else
			begin
				File.delete(path)
			rescue Errno::ENOENT => e
				# okay
			end
			puts "skip (no notes)"
		end
	end

	def generate_audio(dir = nil)
		dir = __data_path(dir)
		if @md
			@md.each_with_index do |page, i|
				generate_audio0(i + 1, page.comments, dir)
			end
		else
			@presentation.slides.each_with_index do |slide, i|
				generate_audio0(i + 1, get_slide_note(slide), dir)
			end
		end
	end
end
