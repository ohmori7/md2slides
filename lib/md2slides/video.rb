require 'open3'

class Presentation
	def generate_slide_video(i, dir)
		img = __data_slide_path(i, '.png', dir)
		audio = __data_slide_path(i, '.m4a', dir)
		video = __data_slide_path(i, '.mp4', dir)

		if File.exists?(audio)
			audioin = "-i \"#{audio}\""
			timeopt = '-shortest'
		else
			audioin = "-f lavfi -i aevalsrc=0"
			timeopt = "-vframes 60"
		end
		cmd = <<~CMD
			ffmpeg -hide_banner -y				\
			    -framerate 15 -loop 1 -i "#{img}"		\
			    #{audioin} -map 0:v:0 -map 1:a:0		\
			    -c:v libx264 -tune stillimage		\
			    -c:a aac -ar #{AUDIO_RATE} -ac 1		\
			    -pix_fmt yuv420p #{timeopt} "#{video}"
		CMD
		msg, errmsg, status = Open3.capture3(cmd)
		if ! status.success?
			raise("ERROR: cannot produce video: #{errmsg}")
		end
	end

	def generate_video(dir = nil)
		dir = __data_path(dir)
		@presentation.slides.each_with_index do |slide, i|
			print "slide \##{i + 1}: generating video..."
			generate_slide_video(i, dir)
			puts "done"
		end

		print "concatenate video files..."
		videolist = 'video-list.txt'
		File.open(File.join(dir, videolist), 'w') do |f|
			@presentation.slides.each_with_index do |slide, i|
				f.puts("file #{__data_slide_path(i, '.mp4')}")
			end
		end
		video = 'video.mp4'
		cmd = <<~CMD
			cd "#{dir}" &&					\
			    ffmpeg -hide_banner -y -f concat -safe 0	\
			    -i "#{videolist}" -c copy "#{video}"
		CMD
		msg, errmsg, status = Open3.capture3(cmd)
		if ! status.success?
			raise("ERROR: cannot produce video: #{errmsg}")
		else
			puts 'done'
		end
	end
end
