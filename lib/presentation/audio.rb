class Presentation
	def generate_audio0(i, slide, dir)
		print "slide \##{i + 1}: generating audio... "
		notes = get_slide_note(slide)
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
			audiorate = 24000
			cmd = <<~CMD
				ffmpeg -hide_banner -y				\
				    -f lavfi -t #{heading_silence}		\
				    -i anullsrc=r=#{audiorate}:cl=mono		\
				    -i #{opath}					\
				    -f lavfi -t #{trailing_silence}		\
				    -i anullsrc=r=#{audiorate}:cl=mono		\
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
		@presentation.slides.each_with_index do |slide, i|
			generate_audio0(i, slide, dir)
		end
	end
end
