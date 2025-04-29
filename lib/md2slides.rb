$:.unshift File.dirname(File.dirname(File.realpath(__FILE__)))

module Md2slides
	class Error < StandardError; end

	# XXX: platform independent path configuration...
	ENV['GOOGLE_APPLICATION_CREDENTIALS'] ||= File.join(Dir.home, ".config/gcloud/credentials.json")

	require 'md2slides/md'
	require 'md2slides/presentation'
	require 'md2slides/text_to_speech'
	require 'md2slides/audio'
	require 'md2slides/video'
	require "md2slides/version"
end
