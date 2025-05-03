require "googleauth"
#require "google/apis/people_v1"
require "google/apis/slides_v1"
require "google/apis/drive_v3"

class Presentation
	APPLICATION_NAME = 'md2slides'

	GOOGLE_OAUTH_SCOPE = [
		"https://www.googleapis.com/auth/drive",
#		"https://www.googleapis.com/auth/userinfo.email",
#		"https://www.googleapis.com/auth/userinfo.profile",
		"https://www.googleapis.com/auth/presentations",
	]

	attr_reader :id

	def self.filename_sanitize(s)
		s&.gsub(/[\/\\:\*\?"<>\|]/, '')
	end

	def initialize(md = nil)
		@md = md
		url = md&.attributes[:url]
		if url =~ %r{https://docs.google.com/presentation/d/([^\/ ]+).*$}
			@id = $1
		elsif url
			raise("ERROR: invalid URL: #{url}")
		end

		@authorizer = Google::Auth::ServiceAccountCredentials.make_creds(
			json_key_io: File.open(ENV['GOOGLE_APPLICATION_CREDENTIALS']),
			scope: GOOGLE_OAUTH_SCOPE)

		@slides_service = Google::Apis::SlidesV1::SlidesService.new
		@slides_service.client_options.application_name = APPLICATION_NAME
		@slides_service.authorization = @authorizer

		@drive_service = Google::Apis::DriveV3::DriveService.new
		@drive_service.client_options.application_name = APPLICATION_NAME
		@drive_service.authorization = @authorizer

		@requests = []

		# XXX: this seript always runs by an API user...
		#people_service = Google::Apis::PeopleV1::PeopleServiceService.new
		#people_service.authorization = @authorizer
		#profile = people_service.get_person("people/me", person_fields: "names,emailAddresses")
		#name = profile.names.first.display_name
		#email = profile.email_addresses.first.value
		#puts "#{name}: #{email}"
	end

	def __get_presentation
		begin
			@authorizer.fetch_access_token!
			@presentation = @slides_service.get_presentation(@id)
		rescue => e
			require 'webrick'
			raise(e, "#{e.message} (#{e.status_code} " +
			    "#{WEBrick::HTTPStatus.reason_phrase(e.status_code)})\n" +
			    "#{e.full_message}")
		end
	end

	def exists?
		return false if ! @id
		if @presentation.nil?
			__get_presentation
		end
		!! @presentation
	end

	def existence_check
		if ! exists?
			raise("presentation (ID: #{@id}) does not exists!!!")
		end
	end

	def url
		@id && "https://docs.google.com/presentation/d/#{@id}/edit"
	end

	def extent
		existence_check
		width = @presentation.page_size.width.magnitude
		height = @presentation.page_size.height.magnitude
		unit = @presentation.page_size.width.unit
		return width, height, unit
	end

	def width
		extent[0]
	end

	def height
		extent[1]
	end

	def stick_out_check
		msgs = []
		@presentation.slides.each_with_index do |slide, i|
			slide.page_elements.each do |element|
				next unless element.shape
				next unless element.transform
				x1 = element.transform.translate_x || 0
				x2 = x1 + element.size.width.magnitude rescue 0
				y1 = element.transform.translate_y || 0
				y2 = y1 + element.size.width.magnitude rescue 0
				puts "width: #{width}, height: #{height}"
				if x2 > width || y2 > height || x1 < 0 || y1 < 0
					msgs.push("slide #{i + 1}: sticking out: (#{x1},#{y1})-(#{x2},#{y2})")
				end
			end
		end
		raise(msgs.join("\n")) unless msgs.empty?
	end

	def create(name)
		if exists?
			raise("already presentation exists!!")
		end
		presentation0 = Google::Apis::SlidesV1::Presentation.new(title: name)
		@presentation = @slides_service.create_presentation(presentation0)
		@id = @presentation.presentation_id
		puts "Create presentation #{name}: #{url}"
	end

	def delete
		existence_check
		begin
			@drive_service.delete_file(@id)
			@presentation = nil
			puts "deleted ID: #{@id}"
		rescue Google::Apis::ClientError => e
			puts "ERROR: failed deleting #{@id}: #{e.full_message}"
		end
	end

	def share(user)
		existence_check
		permission = Google::Apis::DriveV3::Permission.new(
		    type: 'user',
		    role: 'writer', # 'reader', 'commenter', 'writer'
		    email_address: user
		    )
		@drive_service.create_permission(@id, permission, fields: "id")
	end

	def __request
		return if @requests.empty?
		batch_update_request = Google::Apis::SlidesV1::BatchUpdatePresentationRequest.new(requests: @requests)
		begin
			@slides_service.batch_update_presentation(@id, batch_update_request)
			@requests = []
		rescue => e
			raise(e, "#{e.body}\n#{e.full_message}")
		end
		@presentation = @slides_service.get_presentation(@id)
	end

	def delete_object(object_id)
		@requests.push({
			delete_object: {
				object_id_prop: object_id,
			}
		})
	end

	def create_slide(layout = 'TITLE_AND_BODY', insertion_index = nil)
		insertion_index ||= @presentation.slides&.size.to_i	# at the tail
		#
		# layout can be:
		# https://developers.google.com/apps-script/reference/slides/predefined-layout
		#
		@requests.push({
			create_slide: {
				#
				# XXX: object ID should be specified for performance...
				#
#				object_id_prop: object_id_prop,
				insertion_index: insertion_index,
				slide_layout_reference: {
					predefined_layout: layout,
				}
			}
		})
		__request
		@presentation.slides[insertion_index]
	end

	def delete_text(element)
		return if ! element.shape.instance_variable_defined?(:@placeholder)
		return if ! element.shape.instance_variable_defined?(:@text)
		@requests.push({
			delete_text: {
				object_id_prop: element.object_id_prop,
				text_range: {
					type: 'ALL'
				}
			}
		})
	end

	def update_text(element, text)
		delete_text(element)
		return if text.nil? || text.empty?
		@requests.push({
			insert_text: {
				object_id_prop: element.object_id_prop,
				insertion_index: 0,
				text: text
			}
		})
	end

	def set_bullet(element, bullet)
		return if bullet.nil?
		@requests.push({
			create_paragraph_bullets: {
				object_id_prop: element.object_id_prop,
				text_range: {
					type: 'ALL',
				},
				bullet_preset: bullet,
			}
		})
	end

	def find_element(slide, type)
		slide&.page_elements&.find do |e|
			case e.shape&.placeholder&.type
			when type
				true
#			else
#				p e.shape&.placeholder&.type
#				false
			end
		end
	end

	def __get_element_text(element)
		element&.shape&.text&.text_elements&.collect { |e| e.text_run&.content&.strip }&.compact&.join("\n")
	end

	def get_slide_text(slide, re = 'BODY')
		__get_element_text(find_element(slide, re))
	end

	def get_title
		slide = @presentation&.slides.first
		title = get_slide_text(slide, /(^TITLE|[^a-zA-Z]TITLE)$/)
		subtitle = get_slide_text(slide, 'SUBTITLE')
		return title, subtitle
	end

	def set_slide_text(slide, text, re = 'BODY', bullet = 'BULLET_DISC_CIRCLE_SQUARE')
		element = find_element(slide, re)
		if element.nil?
			raise("ERROR: no text element found!!!")
		end
		update_text(element, text)
		set_bullet(element, bullet)
	end

	def set_slide_title(slide, title, re = /(^TITLE|[^a-zA-Z]TITLE)$/)
		set_slide_text(slide, title, re, nil)
	end

	def set_slide_subtitle(slide, title)
		set_slide_title(slide, title, 'SUBTITLE')
	end

	def set_title(title, subtitle = nil)
		existence_check
		if @presentation&.slides&.size.to_i == 0
			create_slide('TITLE')
		end
		slide = @presentation.slides.first
		set_slide_title(slide, title)
		set_slide_subtitle(slide, subtitle)
		__request
	end

	def get_slide_note(slide)
		notes = slide.slide_properties.notes_page
		__get_element_text(find_element(notes, 'BODY'))
	end

	def set_slide_note(slide, text)
		notes = slide.slide_properties.notes_page
		element = find_element(notes, 'BODY')
		if element.nil?
			raise("ERROR: no text box element found in notes!!!")
		end
		update_text(element, text)
	end

	def clear
		existence_check
		n = @presentation.slides&.size.to_i
		while n > 0
			n -= 1
			delete_object(@presentation.slides[n].object_id_prop)
		end
		__request
	end

	def list
		existence_check
		puts "title: #{@presentation.title}"
		puts "pages: #{@presentation.slides.size}"
		@presentation.slides.each_with_index do |slide, i|
			puts "- Slide \##{i + 1} contains #{slide.page_elements.count} elements."
		end
	end

	def list_all
		query = "mimeType = 'application/vnd.google-apps.presentation' and trashed = false"
		response = @drive_service.list_files(q: query, fields: 'files(id, name)', page_size: 100)
		response.files.each do |file|
			puts "#{file.name}: #{file.id}"
		end
	end

	def update
		#
		# XXX: currently, clear all slides...
		#
		if exists?
			clear
		end
		@md.each do |page|
			if page.title_subtitle_only?
				layout = 'TITLE'
			elsif page.title_only?
				layout = 'SECTION_HEADER'
			else
				layout = 'TITLE_AND_BODY'
			end
			slide = create_slide(layout)
			if page.has_title?
				set_slide_title(slide, page.title)
			end
			if page.title_subtitle_only?
				set_slide_subtitle(slide, page.subtitle)
			else
				texts = page.map do |e|
					# calculate the indentation.
					n = (e.attributes&.[](:indent).to_i / 2).to_i
					"\t" * n + e.value
				end.join("\n")
				if texts.size > 0
					set_slide_text(slide, texts)
					# set_slide_text(slide, texts,
					#    'BODY', 'NUMBERED_DIGIT_ALPHA_ROMAN')
				end
			end
			if page.has_comments?
				set_slide_note(slide, page.comments)
			end
		end
		__request
	end

	def __data_path(basedir)
		basedir = '.' if basedir.nil?
		if @md
			title = @md.first.title
			subtitle = @md.first.subtitle
		elsif @presentation
			title, subtitle = get_title
		end
		title = self.class.filename_sanitize(title)
		subtitle = self.class.filename_sanitize(subtitle)
		File.join(basedir, "#{title}-#{subtitle}-#{@id}")
	end

	def __data_slide_path(i, ext, basedir = nil)
		path = "slide-#{i + 1}#{ext}"
		if basedir
			path = File.join(basedir, path)
		end
		path
	end

	# XXX: these do not work when the presentation is not shared globally.
	def export_url(i)
		#@id && "https://docs.google.com/presentation/d/#{@id}/export/png?id=#{@id}&pageid=#{slide.object_id_prop}&width=1920&height=1080"
		@id && "https://docs.google.com/presentation/d/#{@id}/export/png?id=#{@id}&pageid=p#{i}&width=1920&height=1080"
	end

	# XXX: these do not work when the presentation is not shared globally.
	def download_slide0(i, slide, dir)
		url = export_url(i)
		URI.open(url) do |remote_file|
			path = __data_slide_path(i, '.png', dir)
			File.open(path, 'wb') do |file|
				file.write(remote_file.read)
			end
		end
	end

	def download_slide(i, slide, dir)
		print "slide #{i}: downloading..."
		#
		# a size of a width can be: SMALL (200), MEDIUM (800), LARGE (1600)
		# https://developers.google.com/workspace/slides/api/reference/rest/v1/presentations.pages/getThumbnail
		#
		thumbnail = @slides_service.get_presentation_page_thumbnail(
		    @id, slide.object_id_prop, thumbnail_properties_thumbnail_size: 'LARGE')
		URI.open(thumbnail.content_url) do |remote_file|
			path = __data_slide_path(i, '.png', dir)
			File.open(path, 'wb') do |file|
				file.write(remote_file.read)
			end
		end
		puts 'done'
	end

	def download(dir = nil)
		existence_check
		dir = __data_path(dir)
		parent = File.dirname(dir)
		files = Dir.glob("#{File.join(parent, "*#{@id}*")}")
		if files.empty?
			FileUtils.mkdir_p(dir)
		elsif files[0] != dir
			File.rename(files[0], dir)
		end
		lockfile = File.join(dir, '.lock')
		File.open(lockfile, File::RDWR|File::CREAT, 0644) do |f|
			f.flock(File::LOCK_EX | File::LOCK_NB)
			@presentation.slides.each_with_index do |slide, i|
				download_slide(i, slide, dir)
			end
		end
	end
end
