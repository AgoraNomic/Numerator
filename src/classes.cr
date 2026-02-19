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

	def to_hash : Hash
		{
			"id" => @id.to_s,
			"shortname" => @shortname,
			"fullname" => @fullname,
			"cards" => @cards
		}
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

	def get_entities : Array(Entity)
		rs = @conn.query(
			"SELECT id, shortname, fullname, cards FROM entity"
		)

		result = Array(Entity).new

		rs.each do
			id, shortname, fullname, cards = rs.read(UUID, String, String | Nil, Array(Int32))
			result << Entity.new(id, shortname, fullname, cards)
		end

		result
	end

	def get_history : Array(Hash(String, Time | String | Array(Int32) | Nil))
		result = Array(Hash(String, Time | String | Array(Int32) | Nil)).new 100

		rs = @conn.query <<-SQL
				SELECT action.ts, sub.shortname, action.cards, rec.shortname
				FROM action
					LEFT JOIN entity AS sub ON sub.id = action.subject
					LEFT JOIN entity AS rec ON rec.id = action.receiver
				ORDER BY action.ts
			SQL

		rs.each do
			timestamp, subject, cards, receiver = rs.read(Time, String, Array(Int32), String | Nil)
			result << {
				"timestamp" => timestamp,
				"subject" => subject,
				"cards" => cards,
				"receiver" => receiver,
			}
		end

		result
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

	def undo_by_id(id : UUID) : Bool
		action_cards, subject, action_type, entity_cards = @conn.query_one <<-SQL, id, as: {Array(Int32), UUID, String, Array(Int32)}
			SELECT action.cards, action.subject, action.action, entity.cards
			FROM action
			JOIN entity ON action.subject = entity.id
			WHERE action.id = $1
		SQL

		if action_type != "adjust"
			return false
		end

		newcards = entity_cards.zip(action_cards).map do |c|
			result = c[0] + c[1]
			if result < 0
				return false
			end
			result
		end

		@conn.transaction do |tx|
			@conn.exec <<-SQL, id
				DELETE FROM action WHERE id = $1
			SQL

			@conn.exec <<-SQL, newcards, subject
				UPDATE entity SET cards = $1 WHERE id = $2;
			SQL
		end

		true
	end

	def add_note(content : String, range : Range(Time | Nil, Time | Nil))
		@conn.exec <<-SQL, content, range.begin, range.end
			INSERT INTO note (content, start_time, end_time)
			VALUES ($1, $2, $3)
		SQL
	end

	def get_note_text(ts timestamp : Time = Time.utc) : Array(String)
		result = [] of String
		rs = @conn.query <<-SQL, timestamp
			SELECT content FROM note
			WHERE (start_time < $1 OR start_time IS NULL)
				AND ($1 < end_time OR end_time IS NULL)
		SQL

		rs.each do
			result << rs.read(String)
		end

		result
	end

	def close
		@conn.close
	end
end
