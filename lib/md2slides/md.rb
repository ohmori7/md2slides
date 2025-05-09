class MD
	class Page
		include Enumerable

		class Element
			attr_reader :type, :value, :attributes
			def initialize(type, value, attributes)
				@type, @value, @attributes = type, value, attributes
			end

			def to_s
				"#{@type.to_s}: #{@value} (#{@attributes.map { |k, v| "#{k}: #{v}"}.join(",")})"
			end
		end

		def initialize
			@elements = []
			@comments = []
		end

		def add(type, value, attributes = nil)
			return if value.nil? || value.empty?
			case type.to_s
			when /^h([0-9]+)$/
				n = $1.to_i - 1
				attributes ||= {}
				attributes[:indent] = n
			end
			@elements.push(Element.new(type, value, attributes))
		end

		def add_comment(c)
			return if c.nil? || c.empty?
			@comments.push(c)
		end

		def comments
			return nil if @comments.empty?
			@comments.join("\n")
		end

		def has_comments?
			! @comments.empty?
		end

		def has_title?
			@elements[0]&.type == :h1
		end

		def title
			has_title? && @elements[0].value
		end

		def title_only?
			has_title? && @elements.size == 1
		end

		def title_subtitle_only?
			has_title? && @elements.size == 2 &&
			    @elements[1]&.type == :h2
		end

		def subtitle
			title_subtitle_only? && @elements[1]&.value
		end

		def empty?
			@elements.empty? && @comments.empty?
		end

		def each(&block)
			@elements.drop(has_title? ? 1 : 0).each(&block)
		end
	end

	include Enumerable

	attr_reader :attributes

	def initialize(path)
		@pages = []
		@attributes = {}
		load(path)
	end

	def __filename_sanitize(s)
		s.gsub(/[\/\\:\*\?"<>\|]/, '')
	end

	def each(&block)
		@pages.each(&block)
	end

	def size
		@pages.size
	end

	def parse_header(text)
		text.each_line do |l|
			l.strip!
			next if l.empty?
			if l =~ /^([^:]+): *([^ ].*)$/
				k, v = $1.strip, $2.strip
				@attributes[k.to_sym] = v
			else
				raise("ERROR: invalid line in a header: #{l}")
			end
		end
	end

	def parse_page(text)
		page = Page.new
		is_in_comment = false
		text.each_line do |l0|
			l = l0.strip
			next if l.empty?
			if is_in_comment
				if l =~ /(.*) ?-->(.*)$/
					c, left = $1, $2
					page.add_comment(c)
					page.add(:p, left)
					is_in_comment = false
				else
					page.add_comment(l)
				end
			else
				case l
				when /^!.*$/
					# XXX: here, we treat ``!'' as comment out.
					next
				when /^(#+) *(.*)$/
					sharps, title = $1, $2
					h = "h#{sharps.size}"
					page.add(h.to_sym, title)
				when /^[-*] *(.*)$/
					s = $1
					if l0 =~ /^( +).*$/
						indent = { indent: $1.size }
					end
					page.add(:li, s, indent)
				when /^<!-- *(.*)$/
					l = $1
					if l =~ /(.*) ?-->(.*)$/
						c, left = $1, $2
						page.add_comment(c)
						page.add(:p, left)
					else
						is_in_comment = true
						page.add_comment(l)
					end
				else
					page.add(:p, l)
				end
			end
		end
		if ! page.empty?
			@pages << page
		end
	end

	def load(path)
		File.read(path).split('---').each do |text|
			if @attributes.empty?
				parse_header(text)
				next
			end
			parse_page(text)
		end
	end
end
