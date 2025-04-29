#
# this requires:
# gem install google-cloud-text_to_speech
#
require 'google/cloud/text_to_speech'

class Presentation
	def self.text_to_speech(text, filename)
		extname = File.extname(filename)
		if extname
			if filename =~ /^(.*)#{extname}$/
				filename = $1
			else
				raise("invalid extname #{extname} in \"#{filename}\"")
			end
		end
		filename += '.mp3'

		response = Google::Cloud::TextToSpeech.new.synthesize_speech(
		    # XXX: I don't know how to create an object of Google::Cloud::TextToSpeech::SynthesisInput...
		    { text: text },
		    #
		    # Standard is the cheapest.
		    #	ja-JP-Standard-A, B female
		    #	ja-JP-Standard-C, D male
		    # Wavenet is more expensive than standard.
		    #	https://cloud.google.com/text-to-speech/docs/voices?hl=ja
		    #	https://cloud.google.com/text-to-speech/pricing?hl=ja
		    #
		    #{ language_code: 'ja-JP', name: 'ja-JP-Wavenet-B' },
		    { language_code: 'ja-JP', name: 'ja-JP-Standard-D' },
		    { audio_encoding: :MP3 },
		    )

		File.open(filename, 'wb') do |file|
			file.write(response.audio_content)
		end

		return filename
	end
end
