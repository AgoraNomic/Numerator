def create_transmute_card_a(a : Array(Int32)) : Array(Int32)
	cards = Array.new 10, 0
	total = 0
	nums = a.map do |i|
		cards[i] -= 1
	end
	cards[a.sum % 10] += 1

	cards
end

def s_to_card_a(s : String) : Array(Int32)
	result = Array(Int32).new 10, 0
	s.each_char do |c|
		result[c.to_i] += 1
	end
	result
end

def card_a_to_s(a : Array(Int32)) : String
	String.build do |sb|
		idx = 0
		sign = false
		a.each do |n|
			if n < 0
				if !sign
					sign = true
					sb << "-"
				end
				sb << idx.to_s * -n
			end
			idx += 1
		end

		idx = 0
		sign = false
		a.each do |n|
			if n > 0
				if !sign
					sign = true
					sb << "+"
				end
				sb << idx.to_s * n
			end
			idx += 1
		end
	end
end
