def s_to_card_a(s : String) : Array(Int32)
	result = Array(Int32).new 10, 0
	s.each_char do |c|
		result[c.to_i] += 1
	end
	result
end
