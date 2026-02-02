require "db"
require "pg"
require "./classes.cr"
require "./util.cr"

ctx = NumeratorContext.new "postgres://numerator@localhost:5434/numerator"

begin
	case ARGV[0]
	when "enroll", "e"
		ctx.create_entity short: ARGV[1], full: ARGV[2]?
		puts ctx.get_uuid_by_name ARGV[1]
	when "grant", "g"
		ctx.grant(
			ts: Time.parse!(ARGV[1], "%a, %-d %b %Y %H:%M:%S %z"),
			name: ARGV[2],
			cards: s_to_card_a(ARGV[3]),
			comment: ARGV[4]?
		)
	when "revoke", "r"
		ctx.grant(
			ts: Time.parse!(ARGV[1], "%a, %-d %b %Y %H:%M:%S %z"),
			name: ARGV[2],
			cards: s_to_card_a(ARGV[3]).map do |c| -c end,
			comment: ARGV[4]?
		)
	else
		STDERR.puts "Unknown command: #{ARGV[0]}"
		exit 1
	end
ensure
	ctx.close
end
