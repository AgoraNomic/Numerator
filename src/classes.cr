require "db"
require "pg"

class Entity
	@id : UUID
	@shortname : String
	@fullname : String | Nil
	@cards : Array(Int32)

	def initialize(id : UUID, short shortname : String, full fullname : String | Nil, cards : Array(Int32))
		@id = id
		@shortname = shortname
		@fullname = fullname
		@cards = cards
	end
end

class NumeratorContext
	@conn : DB::Database

	def initialize(url : String)
		@conn = DB.open url
	end

	def create_entity(short shortname : String, full fullname : String | Nil = nil)
		@conn.exec "INSERT INTO entity (shortname, fullname) VALUES ($1, $2)", shortname, fullname
	end

	def get_uuid_by_name(name : String) : UUID
		@conn.query_one "SELECT id FROM entity WHERE shortname = $1", name, as: {UUID}
	end

	def get_entity_by_name(name shortname : String) : Entity
		id, fullname, cards = @conn.query_one(
			"SELECT id, fullname, cards FROM entity WHERE shortname = $1", shortname,
			as: {UUID, String | Nil, Array(Int32)}
		)

		Entity.new(id, shortname, fullname, cards)
	end

	def grant(name : String, ts timestamp : Time, cards : Array(Int32), comment : String | Nil = nil)
		ent = get_entity_by_name name
		newcards = ent.@cards.zip(cards).map do |c|
			c[0] + c[1]
		end

		@conn.transaction do |tx|
			@conn.exec <<-SQL, ent.@id, timestamp, cards, comment
				INSERT INTO action (subject, action, ts, cards, comment)
				VALUES ($1, 'adjust', $2, $3, $4);
			SQL

			@conn.exec <<-SQL, newcards, ent.@id
				UPDATE entity SET cards = $1 WHERE id = $2
			SQL
		end

		puts newcards
	end

	def close
		@conn.close
	end
end
