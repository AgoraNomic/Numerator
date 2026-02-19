require "db"
require "pg"
require "crinja"
require "./classes.cr"
require "./util.cr"

ctx = NumeratorContext.new "postgres://numerator@localhost:5434/numerator"

begin
	case ARGV[0]
	when "enroll", "e"
		ctx.create_entity short: ARGV[1], full: ARGV[2]?
		puts ctx.get_uuid_by_name ARGV[1]
	when "grant", "g"
		comment = ARGV[4]?
		comment = comment.gsub "#", ARGV[3] if comment
		ARGV[2].split(",").each do |ent|
			ctx.grant(
				ts: Time.parse!(ARGV[1], "%a, %-d %b %Y %H:%M:%S %z"),
				name: ent,
				cards: s_to_card_a(ARGV[3]),
				comment: comment
			)
		end
	when "revoke", "r"
		ctx.grant(
			ts: Time.parse!(ARGV[1], "%a, %-d %b %Y %H:%M:%S %z"),
			name: ARGV[2],
			cards: s_to_card_a(ARGV[3]).map do |c| -c end,
			comment: ARGV[4]?
		)
	when "undo", "u"
		ARGV[1..].each do |x|
			ctx.undo_by_id UUID.new x
		end
	when "transmute", "m"
		ARGV[2].split(",").each do |ent|
			ARGV[3].split(",").each do |str|
				chars = str.chars
				cards = create_transmute_card_a(chars.map do |x|
					x.to_i
				end)

				ctx.grant(
					ts: Time.parse!(ARGV[1], "%a, %-d %b %Y %H:%M:%S %z"),
					name: ent,
					cards: cards,
					comment: ARGV[4]?
				)
			end
		end
	when "win", "w"
		ctx.grant(
			ts: Time.parse!(ARGV[1], "%a, %-d %b %Y %H:%M:%S %z"),
			name: ARGV[2],
			cards: Array(Int32).new(10, -1),
			comment: ARGV[3]?
		)
	when "report", "p"
		env = Crinja.new
		env.loader = Crinja::Loader::FileSystemLoader.new "template/"

		card_string_filter = Crinja.filter do
			card_a_to_s(target.as_a.map do |v|
				v.to_i
			end)
		end

		env.filters["card_string"] = card_string_filter

		template = env.get_template("report.j2")
		idx = 1
		entities = ctx.get_entities
		puts template.render({
			"notes" => ctx.get_note_text,
			"date" => Time.utc,
			"entities" => entities.map do |e|
				sprintf(
					"%-8s%3s%s",
					e.@shortname,
					e.@fullname ? " [#{idx}]" : "    ",
					e.@cards.map do |c|
						sprintf "  %04d", c
					end.sum
				)
			end,
			"long_names" => entities.select do |x|
				x.@fullname != nil
			end.map_with_index do |x, i|
				[x.@fullname, i + 1]
			end,
			"history" => ctx.get_history
		})
	when "note", "n"
		start_time = nil
		end_time = nil
		if ARGV[2]?
			start_time_str, end_time_str = ARGV[2].split ".."
			start_time = Time.parse_utc(start_time_str, "%Y-%m-%d") unless start_time_str.empty?
			end_time = Time.parse_utc(end_time_str, "%Y-%m-%d") unless end_time_str.empty?
		end

		ctx.add_note ARGV[1], start_time..end_time
	else
		STDERR.puts "Unknown command: #{ARGV[0]}"
		exit 1
	end
ensure
	ctx.close
end
