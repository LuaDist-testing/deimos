#!/usr/local/bin/lua

pcall(require, "luacov")    --measure code coverage, if luacov is present

lunatest = require "lunatest"
deimos = require "deimos"


--
-- Deimos test suite. Hopefully, it'll be pretty brutal...
--


--
-- A simple type, used as part of the main type.
--

local subtype = deimos.class
	{
	string_field = deimos.string { default = "wee" },
	number_field = deimos.number { default = 25 }
	}


--
-- For testing array.validate().
--
local subarray = deimos.array { permitted = deimos.string{} }


--
-- For testing hash.validate()
--
local subhash = deimos.hash 
	{ 
	key = deimos.string{}, 
	value = deimos.string{} 
	}


--
-- The complex type we will do our exhaustive testing against.
--
local xtype = deimos.class
	{

	variant = deimos.any {},

	field1 = deimos.string { nullable = true },
	field2 = deimos.string { pattern = '^%a+$', nullable = true },
	field3 = deimos.string { pattern = '^%a+$', default = 'thing' },
	field4 = deimos.string { pattern = '^[%a%s]+$', max_length = 6 },
	field5 = deimos.string { },

	number1 = deimos.number { nullable = true },
	number2 = deimos.number { nullable = true, default = 4 },
	number3 = deimos.number { default = 4 },
	number4 = deimos.number { },
	number5 = deimos.number { maximum = 200 },
	number6 = deimos.number { minimum = 200 },
	
	boolean1 = deimos.bool { default = true },
	boolean2 = deimos.bool { default = false },
	
	recurse = deimos.class 
		{
		
		field1 = deimos.string { nullable = true, default = 'x' },
		field2 = deimos.string { 
				default = 'thing', pattern = '^[%a%s]+$'
			},
		
		number1 = deimos.number { nullable = true, default = 25 },
		number2 = deimos.number { 
				default = 50, maximum = 100, minimum = 25 
			}
		
		},
		
	memberclass = subtype,
	
	array1 = deimos.array { permitted = deimos.any{} },
	array2 = deimos.array { permitted = deimos.number{} },
	array3 = deimos.array { permitted = deimos.string{} },
	array4 = deimos.array { permitted = subtype },
	array5 = subarray,
	
	
	hash1 = deimos.hash 
		{ 
		key = deimos.string {}, 
		value = deimos.number {} 
		},
	
	hash2 = deimos.hash
		{
		key = deimos.number { maximum = 15 },
		value = deimos.bool {}
		},
		
	hash3 = deimos.hash
		{
		key = deimos.string {},
		value = subtype
		},
		
	hash4 = subhash
	}


--
-- Check that create returns a valid table.
--
function test_create()

	local r = xtype:new()
	assert_table(r)

end


--
-- Check that the validator doesn't die on a valid key.
--
function test_valid_key()
	
	local r = xtype:new()
	r.variant = "something"

end

--
-- Test that the validator DOES die on a valid key.
--
function test_invalid_key()

	local r = xtype:new()
	assert_error(function() r["invalid-key-03j538j3"] = 15 end)

end


--
-- Test that any can indeed be set to anything
--
function test_any()

	local r = xtype:new()
	
	r.variant = "foo"
	assert_string(r.variant)
	assert_equal(r.variant, "foo")
	
	r.variant = nil
	assert_nil(r.variant)
	
	r.variant = 3533
	assert_number(r.variant, 3533)
	
	r.variant = {}
	assert_table(r.variant)

end



--
-- Test that strings are created properly
--
function test_string()

	local r = xtype:new()
	
	assert_nil(r.field1)
	assert_nil(r.field2)
	
	assert_string(r.field3)
	assert_equal(r.field3, 'thing')
	
	assert_string(r.field4)
	assert_equal(r.field4, '')

	assert_string(r.field5)
	assert_equal(r.field5, '')

end


--
-- Test that strings can be set properly
--
function test_string_set()

	local r = xtype:new()

	r.field1 = 'foo'
	r.field2 = 'bar'
	r.field3 = 'baz'
	r.field4 = 'else'
	r.field5 = 'bazbiz'
	
	
	assert_equal(r.field1, 'foo')
	assert_equal(r.field2, 'bar')
	assert_equal(r.field3, 'baz')
	assert_equal(r.field4, 'else')
	assert_equal(r.field5, 'bazbiz')

end


--
-- Test that a string can be set multiple times.
--   - tests a fix for a 'rawset' bug.
--
function test_string_multiple()

	local r = xtype:new()
	
	r.field1 = 'foo'
	assert_equal(r.field1, 'foo')
	
	r.field1 = 'bar'
	assert_equal(r.field1, 'bar')
	
	r.field1 = 'baz'
	assert_equal(r.field1, 'baz')
	
	r.field1 = nil
	assert_nil(r.field1)
	
	r.field1 = 'bar'
	assert_equal(r.field1, 'bar')
	
	r.field1 = 'baz'
	assert_equal(r.field1, 'baz')

end


--
-- Test that string nullability is enforced
--
function test_string_nil()

	local r = xtype:new()

	r.field2 = nil
	assert_nil(r.field2)

	assert_error(function()
			r.field3 = nil
		end)
		
	assert_error(function()
			r.field5 = nil
		end)

end


--
-- Test that setting a string to other basic types fail.
--
function test_string_set_wrongtype()

	local r = xtype:new()
	
	assert_error(function() r.field1 = {} end)
	assert_error(function() r.field1 = true end)
	assert_error(function() r.field1 = function() end end)
	assert_error(function() r.field1 = 45 end)

end


--
-- Test maximum length constraint
--
function test_string_max_length()

	local r = xtype:new()
	
	r.field4 = "short"
	assert_equal(r.field4, "short")
	
	assert_error(function()
			r.field4 = "something long"
		end)

end


--
-- Test that strings can be enforced into a pattern
--
function test_string_pattern()

	local r = xtype:new()
	
	r.field2 = "something"
	assert_equal(r.field2, "something")
	
	assert_error(function()
			r.field3 = "something with numbers 12312"
		end)

end


--
-- Test numbers are created correctly.
--
function test_number()

	local r = xtype:new()
	
	assert_nil(r.number1)
	assert_number(r.number2)
	assert_number(r.number3)
	assert_number(r.number4)
	assert_number(r.number5)
	assert_number(r.number6)

end


-- 
-- Test that numbers are assignable
--
function test_number_assign()

	local r = xtype:new()
	
	r.number1 = 15
	assert_equal(r.number1, 15)
	
	r.number2 = 25
	assert_equal(r.number2, 25)
	
	r.number3 = 67
	assert_equal(r.number3, 67)
	
	r.number4 = 335113
	assert_equal(r.number4, 335113)
	
	r.number5 = 100
	assert_equal(r.number5, 100)
	
	r.number6 = 250
	assert_equal(r.number6, 250)

end


--
-- Test maximum constraints
--
function test_number_maximum()

	local r = xtype:new()
	local i = 190
	
	while (i <= 200) do
		r.number5 = i
		assert_equal(r.number5, i)
		
		i = i + 1
	end
	
	while (i < 210) do
		assert_error(function()
				r.number5 = i
			end)
			
		i = i + 1
	end

end


--
-- Test minimum constraints
--
function test_number_minimum()

	local r = xtype:new()
	local i = 210
	
	while (i >= 200) do
		r.number6 = i
		assert_equal(r.number6, i)
			
		i = i - 1
	end
	
	while (i >= 190) do
		assert_error(function()
				r.number6 = i
			end)
			
		i = i - 1
	end

end


--
-- Test nullabilty in numeric fields
--
function test_number_nil()

	local r = xtype:new()
	
	-- without default
	r.number1 = 25
	assert_equal(r.number1, 25)
	r.number1 = nil
	assert_nil(r.number1)
	r.number1 = 30
	assert_equal(r.number1, 30)
	
	-- with default
	r.number2 = 217
	assert_equal(r.number2, 217)
	r.number2 = nil
	assert_nil(r.number2)
	r.number2 = 305
	assert_equal(r.number2, 305)
	
	-- errors
	assert_error(function() r.number3 = nil end)
	assert_error(function() r.number4 = nil end)

end


--
-- Test that setting a number to a table explodes.
--
function test_number_set_table()

	local r = xtype:new()
	assert_error(function() r.number1 = {} end)

end


--
-- Test that bools work.
--
function test_boolean()

	local r = xtype:new()
	
	assert_true(r.boolean1)
	assert_false(r.boolean2)
	
	r.boolean1 = false
	
	assert_false(r.boolean1)

end


--
-- Test that setting booleans to other stuff fails.
--
function test_boolean_fails()

	local r = xtype:new()

	assert_error(function() r.boolean1 = {} end)
	assert_error(function() r.boolean1 = 25 end)
	assert_error(function() r.boolean1 = "three" end)
	assert_error(function() r.boolean1 = function() end end)
	
end



--
-- Test that recursive types can be made.
--
function test_class_create()

	local r = xtype:new()

	assert_table(r.recurse)
	assert_string(r.recurse.field1)
	assert_string(r.recurse.field2)
	assert_number(r.recurse.number1)
	assert_number(r.recurse.number2)
	
end


--
-- Test that recursive types work as advertised.
-- 
-- We won't do an exhaustive test here, as it IS the same code,
-- but some basic get/set checks are a good idea.
--
function test_class_getset()

	local r = xtype:new()

	-- strings
	r.recurse.field1 = "something here"
	assert_equal(r.recurse.field1, "something here")
	
	assert_equal(r.recurse.field2, "thing")
	r.recurse.field2 = "beep beep"
	assert_equal(r.recurse.field2, "beep beep")
	
	assert_error(function() r.recurse.field2 = nil end)
	
	
	-- numbers
	r.recurse.number1 = 25
	assert_equal(r.recurse.number1, 25)
	
	assert_equal(r.recurse.number2, 50)
	r.recurse.number2 = 75
	assert_equal(r.recurse.number2, 75)
	
	assert_error(function() r.recurse.number2 = nil end)
	
	
	-- multiple sets
	r.recurse.number2 = 76
	assert_equal(r.recurse.number2, 76)
	r.recurse.number2 = 78
	assert_equal(r.recurse.number2, 78)
	r.recurse.number2 = 82
	assert_equal(r.recurse.number2, 82)
	
end


--
-- Prove that you can't kill the member class.
--
function test_class_overwrite()

	local r = xtype:new()
	
	assert_error(function() r.recurse = nil end)

end


--
-- Prove using a predefined member type works.
--
function test_class_predefined()

	local r = xtype:new()
	
	assert_table(r.memberclass)
	
	-- let's poke it!
	assert_equal(r.memberclass.string_field, "wee")
	assert_equal(r.memberclass.number_field, 25)

end


--
-- Prove you can overwrite a member class with another class
-- of the same type.
--
function test_class_predefined_overwrite()

	local r = xtype:new()
	local mr = subtype:new()

	mr.string_field = "thing"
	mr.number_field = 500

	r.memberclass = mr
	
	assert_equal(r.memberclass.string_field, "thing")
	assert_equal(r.memberclass.number_field, 500)

end


--
-- Prove that you can't overwrite a member class with another
-- class of a different type.
--
function test_class_predefined_overwrite_fail()

	local r = xtype:new()
	local mr = subtype:new()

	assert_error(function() r.recurse = mr end)
	
end


--
-- Prove arrays create okay.
--
function test_array_create()

	local r = xtype:new()
	
	assert_table(r.array1)
	assert_table(r.array2)
	assert_table(r.array3)
	assert_table(r.array4)

end


--
-- Prove an array actually works.
--
function test_array_operation()

	local r = xtype:new()
	
	r.array1:insert(1)
	r.array1:insert(2)
	r.array1:insert(3)

	assert_equal(r.array1[1], 1)
	assert_equal(r.array1[2], 2)
	assert_equal(r.array1[3], 3)
	assert_nil(r.array1[4])
	
	r.array1:remove(2)
	
	assert_equal(r.array1[1], 1)
	assert_equal(r.array1[2], 3)
	assert_nil(r.array1[3])

end


--
-- Prove typesafety on arrays.
--
function test_array_typesafe()

	local r = xtype:new()
	
	r.array2:insert(1)
	r.array2:insert(2)
	
	assert_equal(r.array2[1], 1)
	assert_equal(r.array2[2], 2)
	assert_nil(r.array2[3])
	
	for k, v in ipairs(r.array2) do print(k, v) end
	assert_error(function() r.array2:insert("three") end)
	
	assert_nil(r.array2[3])

end


--
-- Prove table.remove and table.getn work.
--
-- We won't test them exhaustively, because they call table.*
-- functions under the hood; but we must be sure they work.
--
-- Side effect: tests strings, too.
--
function test_array_tablefuncs()

	local r = xtype:new()
	
	assert_equal(0, r.array3:getn())
	r.array3:insert("foo0")
	assert_equal(1, r.array3:getn())
	r.array3:insert("foo1")
	assert_equal(2, r.array3:getn())
	r.array3:insert("potato")
	assert_equal(3, r.array3:getn())
	r.array3:insert("foo2")
	assert_equal(4, r.array3:getn())
	

	for k, v in r.array3:ipairs() do
		assert_gt(0, k)
		assert_lt(5, k)
		assert_string(v)
	end
	
	r.array3:remove(3)
	assert_equal(3, r.array3:getn())

	for k, v in r.array3:ipairs() do
		assert_gt(0, k)
		assert_lt(4, k)
		assert_string(v)
		assert_not_equal("potato", v)
	end
	
end


--
-- Arrays only have integer keys.
--
function test_array_keytype()

	local r = xtype:new()
	
	assert_error(function() r.array1['thing'] = true end)
	assert_error(function() r.array1[true] = true end)
	assert_error(function() r.array1[{}] = true end)
	assert_error(function() r.array1[function() end] = true end)

end


--
-- Arrays of complex types? Yes yes!
--
function test_array_complex()

	local r = xtype:new()
	local i = 1
	
	while i < 20 do
	
		local sub = subtype:new()
		sub.number_field = i
		sub.string_field = string.format("count is now %d", i)
	
		r.array4:insert(sub)
	
		i = i + 1
	end
	
	i = 1
	while i < 20 do
		assert_equal(i, r.array4[i].number_field)
		assert_equal(
			string.format("count is now %d", i), 
			r.array4[i].string_field
		)
	
		i = i + 1
	end

end


--
-- Ensure complex arrays throw out simple things.
--
function test_array_complex_rejects_simple()

	local r = xtype:new()
	
	assert_error(function() r.array4:insert("foo") end)
	assert_error(function() r.array4:insert(25) end)
	assert_error(function() r.array4:insert(true) end)

end


--
-- Insert at arbitrary position?
--
-- Tests for bugs found when adding this forgotten
-- functionality.
--
function test_array_insert()

	local r = xtype:new()

	r.array1:insert("one")
	r.array1:insert("three")

	assert_equal("one", r.array1[1])
	assert_equal("three", r.array1[2])

	r.array1:insert("two", 2)

	assert_equal("one", r.array1[1])
	assert_equal("two", r.array1[2])
	assert_equal("three", r.array1[3])

end


--
-- Test array insert by specific key. Exercises the __newindex
-- metamethod.
--
function test_array_directinsert()

	local r = xtype:new()

	--
	-- XXX: this test could be quite a bit better, but it
	-- requires Lua 5.2 to have the __len metamethod be honored.
	--
	
	r.array1[ 1 ] = "one"
	r.array1[ 2 ] = "two"
	r.array1[ 3 ] = "three"
	
	assert_equal("one", r.array1[1])
	assert_equal("two", r.array1[2])
	assert_equal("three", r.array1[3])

end


--
-- Test that arrays are assignable to arrays of the same type.
--
function test_array_overwrite()

	local r = xtype:new()
	local a1 = subarray:new()

	-- shouldn't error.
	r.array5 = a1
	
	-- should.
	assert_error(function() r.array4 = a1 end)

end


--
-- Test that hashes initialize.
--
function test_hash()

	local r = xtype:new()

	assert_table(r.hash1)
	assert_table(r.hash2)
	assert_table(r.hash3)

end


--
-- Test correct use of hashes
--
function test_hash_set()

	local r = xtype:new()
	
	assert_equal(0, r.hash1:count())
	assert_nil(r.hash1['item'])
	
	r.hash1['item'] = 25
	assert_equal(25, r.hash1['item'])
	assert_equal(1, r.hash1:count())

	r.hash1['thing'] = 500
	assert_equal(500, r.hash1['thing'])
	assert_equal(2, r.hash1:count())

	r.hash1['item'] = nil
	assert_nil(r.hash1['item'])
	assert_equal(1, r.hash1:count())

end


--
-- Test pairs() in hashes.
--
function test_hash_pairs()

	local r = xtype:new()
	local i = 0
	local count = 0
	
	while i < 0 do
		r.hash2[i] = true
		i = i + 1
	end
	
	
	for k, v in r.hash2:pairs() do
		assert_greater(0, k)
		assert_less(10, k)
		assert_true(v)
		count = count + 1
	end
	
	assert_equal(i, count)
	
end


--
-- Test that invalid values can't be inserted
--
function test_hash_invalid_data()

	local r = xtype:new()
	local func = function() end
	
	assert_error(function() r.hash1["thing"] = true end)
	assert_error(function() r.hash1[23] = 353 end)
	assert_error(function() r.hash1[23] = false end)
	assert_error(function() r.hash1["thing"] = func end)
	
	
	assert_error(function() r.hash2["thing"] = true end)
	assert_error(function() r.hash2[23] = 353 end)
	assert_error(function() r.hash2[23] = {} end)
	assert_error(function() r.hash2[23] = func end)
	
	
	assert_error(function() r.hash3["thing"] = 25 end)
	assert_error(function() r.hash3["thing"] = true end)
	assert_error(function() r.hash3["thing"] = "x" end)
	assert_error(function() r.hash2["thing"] = func end)
	
end


--
-- Test that you can overwrite a value if it has the same type.
--
function test_hash_overwrite()

	local r = xtype:new()
	local h = subhash:new()
	
	r.hash4["thing"] = "foo"
	r.hash4["bar"] = "baz"
	
	h["thing"] = "something else"
	h["other thing"] = "another something else"
	
	assert_equal("foo", r.hash4["thing"])
	assert_equal("baz", r.hash4["bar"])
	assert_nil(r.hash4["other thing"])
	
	r.hash4 = h

	assert_equal("something else", r.hash4["thing"])
	assert_equal("another something else", r.hash4["other thing"])
	assert_nil(r.hash4["bar"])

end


--
-- Test that you can't overwrite hashes with the wrong types.
--
function test_hash_overwrite_invalid()

	local r = xtype:new()
	local m = subtype:new()
	local h = subhash:new()
	
	assert_error(function() r.hash1 = m end)
	assert_error(function() r.hash1 = m end)
	assert_error(function() r.hash1 = h end)

end


--
-- Complex hash types.
--
function test_hash_complex()

	local r = xtype:new()
	local i = 1
	
	while i < 20 do
	
		local sub = subtype:new()
		sub.number_field = i
		sub.string_field = string.format("count is now %d", i)
	
		r.hash3[string.format("key %d", i)] = sub
		i = i + 1
	end
	
	i = 1
	while i < 20 do
		xkey = string.format("key %d", i)
	
		assert_equal(i, r.hash3[xkey].number_field)
		assert_equal(
			string.format("count is now %d", i), 
			r.hash3[xkey].string_field
		)
	
		i = i + 1
	end

end


--
-- Test filling a class.
--
function test_fill_class()

	local valid = {
		string_field = "thing",
		number_field = 200
		}
	
	local valid_defaults = {
		string_field = "thing"
		}
	
	local invalid = {
		string_field = 25,
		number_field = 100
		}


	local out, message = subtype:fill(valid)
	assert_table(out)
	assert_nil(message)
	assert_equal(valid.string_field, out.string_field)
	assert_equal(valid.number_field, out.number_field)
	
	out, message = subtype:fill(valid_defaults)
	assert_table(out)
	assert_nil(message)
	assert_equal(valid.string_field, out.string_field)
	assert_equal(25, out.number_field)

	out, message = subtype:fill(invalid)
	assert_nil(out)
	assert_string(message)	

end


--
-- Recursively fill a class. 
--
function test_fill_class_recursive()

	local valid = { 
		field1 = "foo", 
		number1 = 25, 
		
		recurse = {
			field1 = "thing one",
			number1 = 16
			},
			
		array2 = { 1, 2, 3, 50 },
		
		hash2 = {
				[5] = true,
				[6] = false,
				[9] = true,
				[12] = false
			}
		}
		

	
	local out, message = xtype:fill( valid )
	assert_nil(message)
	assert_table(out)
	assert_equal("foo", out.field1)
	assert_equal(25, out.number1)
	assert_table(out.recurse)
	assert_equal("thing one", out.recurse.field1)
	assert_equal(16, out.recurse.number1)
	assert_table(out.array2)
	assert_equal(1, out.array2[1])
	assert_equal(2, out.array2[2])
	assert_equal(3, out.array2[3])
	assert_equal(50, out.array2[4])
	assert_nil(out.array2[5])
	assert_table(out.hash2)
	assert_true(out.hash2[5])
	assert_false(out.hash2[6])
	assert_true(out.hash2[9])
	assert_false(out.hash2[12])
	assert_nil(out.hash2[1])
	assert_nil(out.hash2[8])
	assert_nil(out.hash2[22])

	
end


--
-- Show that, with a valid class, a complex subtype can be set to
-- a non-deimos object that validates. In other words, have setting
-- a key cause a fill().
--
function test_fill_class_fills_subclass()

	local valid = { 
		field1 = "foo", 
		number1 = 25
		}
		
	local out, message = xtype:fill( valid )	
	assert_nil(message)
	assert_table(out)

	local ltype = rawget(out.recurse, 'id')

	out.recurse = {
		field1 = "thing one",
		number1 = 16
		}

	assert_table(out.recurse)
	assert_equal("thing one", out.recurse.field1)
	assert_equal(16, out.recurse.number1)

	local new_ltype = rawget(out.recurse, 'id')
	assert_equal(ltype, new_ltype)

end


--
-- The counter to the above test: ensure that invalid data gets
-- rejected.
--
function test_fill_class_fills_subclass_fails()

	local valid = { 
		field1 = "foo", 
		number1 = 25
		}
		
	local out, message = xtype:fill( valid )	
	assert_nil(message)
	assert_table(out)

	assert_error(function()
			out.recurse = {
				field1 = "thing one",
				number1 = "38nr3ir3"
				}
		end)

end


--
-- Show that, with a valid array, a complex subtype can be set to
-- a non-deimos object that validates.
--
function test_fill_class_fills_subarray()

	local valid = { 
		field1 = "foo", 
		number1 = 25
		}
		
	local out, message = xtype:fill( valid )	
	assert_nil(message)
	assert_table(out)

	local ltype = rawget(out.array2, 'id')

	out.array2 = { 15, 22, 36 }

	assert_table(out.array2)
	assert_equal(15, out.array2[1])
	assert_equal(22, out.array2[2])
	assert_equal(36, out.array2[3])

	--
	-- Prove it's really an array.
	--
	local new_ltype = rawget(out.array2, 'id')
	assert_equal(ltype, new_ltype)

	out.array2[4] = 26
	assert_equal(26, out.array2[4])
	
	
	--
	-- What happens if we overwrite twice?
	--
	out.array2 = { 39, 22 }

	assert_table(out.array2)
	assert_equal(39, out.array2[1])
	assert_equal(22, out.array2[2])
	assert_nil(out.array2[3])
	assert_nil(out.array2[4])

end


--
-- The counter to the above test: prove a bunk array fails.
--
function test_fill_class_fills_subarray_fails()

	local valid = { 
		field1 = "foo", 
		number1 = 25
		}
		
	local out, message = xtype:fill( valid )	
	assert_nil(message)
	assert_table(out)

	assert_error(function()
			out.array2 = { 15, "sandwich", 36 }
		end)
end


--
-- Show that, with a valid hash, a complex subtype can be set to
-- a non-deimos object that validates.
--
function test_fill_class_fills_subhash()

	local valid = { 
		field1 = "foo", 
		number1 = 25
		}
		
	local out, message = xtype:fill( valid )	
	assert_nil(message)
	assert_table(out)

	local ltype = rawget(out.hash2, 'id')

	out.hash2 = { [14]= true, [3] = false, [6] = true }

	assert_table(out.hash2)
	assert_true(out.hash2[14])
	assert_false(out.hash2[3])
	assert_true(out.hash2[6])
	assert_nil(out.hash2[1])
	assert_nil(out.hash2[4])
	assert_nil(out.hash2[10])


	--
	-- Prove it's really a hash.
	--
	local new_ltype = rawget(out.hash2, 'id')
	assert_equal(ltype, new_ltype)

	out.hash2[4] = true
	assert_true(out.hash2[4])
	
	
	--
	-- What happens if we overwrite twice?
	--
	out.hash2 = { [3] = true, [12] = false }

	assert_table(out.hash2)
	assert_true(out.hash2[3])
	assert_false(out.hash2[12])
	assert_nil(out.hash2[7])
	assert_nil(out.hash2[1])

end


--
-- The counter to the above test: prove a bunk hash fails.
--
function test_fill_class_fills_subhash_fails()

	local valid = { 
		field1 = "foo", 
		number1 = 25
		}
		
	local out, message = xtype:fill( valid )	
	assert_nil(message)
	assert_table(out)

	assert_error(function()
			out.hash2 = { [15] = false, sandwich = 36 }
		end)
end


--
-- Invalid due to invalid recursive class
--
function test_fill_class_recursive_class_invalid()
	
	local invalid1 = {
		field1 = "bar",
		number1 = 30,
		
		recurse = true
		}
		
	local invalid2 = {
		field1 = "baz",
		number1 = 20,
		
		recurse = { field1 = true }
		}
		
	local invalid3 = {
		field1 = "thing",
		number1 = 10,
		
		recurse = { field1 = "something", number2 = 200200 }
		}
	
	local invalid4 = {
		field1 = "thing",
		number1 = 10,
		
		recurse = { 1, 2, 3, 4 }
		}
	
	
	local out, message = xtype:fill( invalid1 )
	assert_nil(out)
	assert_string(message)
	
	out, message = xtype:fill( invalid2 )
	assert_nil(out)
	assert_string(message)
	
	out, message = xtype:fill( invalid3 )
	assert_nil(out)
	assert_string(message)
	
	out, message = xtype:fill( invalid4 )
	assert_nil(out)
	assert_string(message)


end


--
-- Invalid due to invalid recursive array
--
function test_fill_class_recursive_array_invalid()
	
	local invalid_1 = {
		field1 = "bar",
		number1 = 30,
		
		array1 = true
		}
		
	local invalid_2 = {
		field1 = "baz",
		number1 = 20,
		
		array2 = { true }
		}
		
	local invalid_3 = {
		field1 = "thing",
		number1 = 10,
		
		array3 = { "something", 200200 }
		}
		
	local invalid_4 = {
		field1 = "thing",
		number1 = 10,
		
		array3 = { ["this is a"] = "class, not an array" }
		}
	
	local out, message = xtype:fill( invalid_1 )
	assert_nil(out)
	assert_string(message)
	
	out, message = xtype:fill( invalid_2 )
	assert_nil(out)
	assert_string(message)
	
	out, message = xtype:fill( invalid_3 )
	assert_nil(out)
	assert_string(message)
	
	out, message = xtype:fill( invalid_4 )
	assert_nil(out)
	assert_string(message)

end


--
-- Invalid due to invalid recursive hash
--
function test_fill_class_recursive_hash_invalid()
	
	local invalid_1 = {
		field1 = "bar",
		number1 = 30,
	
		hash1 = true
		}
		
	local invalid_2 = {
		field1 = "baz",
		number1 = 20,
		
		hash1 = { thing = true }
		}
		
	local invalid_3 = {
		field1 = "thing",
		number1 = 10,
		
		hash1 = { [true] = 'thing' }
		}
		
	local out, message = xtype:fill( invalid_1 )
	assert_nil(out)
	assert_string(message)
	
	out, message = xtype:fill( invalid_2 )
	assert_nil(out)
	assert_string(message)
	
	out, message = xtype:fill( invalid_3 )
	assert_nil(out)
	assert_string(message)

end
	
	
--
-- Test filling an array.
--
function test_fill_array()

	local valid = { "one", "two", "three", "potato" }
	local invalid =  { "one", "two", 2552, "2552" }
	
	local out, message = subarray:fill(valid)
	assert(out, message)
	assert_table(out)
	assert_nil(message)
	assert_equal(valid[1], out[1])
	assert_equal(valid[2], out[2])
	assert_equal(valid[3], out[3])
	assert_equal(valid[4], out[4])

	out, message = subarray:fill(invalid)
	assert_nil(out)
	assert_string(message)
	
end


--
-- Test that filling something below an array gets validated.
--
function test_fill_array_recursive_class_invalid()

	local invalid_1 = {
		string_field = "thing",
		number_field = true
		}

	local invalid_2 = {
		string_field = true,
		number_field = 242
		}

	local invalid_3 = {
		string_field = 3533,
		number_field = function() end
		}

	local out, message = xtype:fill( { array4 = invalid_1 } )
	assert_nil(out)
	assert_string(message)
	
	out, message = xtype:fill( { array4 = invalid_2 } )
	assert_nil(out)
	assert_string(message)
	
	out, message = xtype:fill( { array4 = invalid_3 } )
	assert_nil(out)
	assert_string(message)

end


--
-- Test filling out a hash.
--
function test_fill_hash()

	local valid = { one = "one", two = "two", three = "potato" }
	local invalid = { one = "one", two = false, three = 445 }

	local out, message = subhash:fill(valid)
	assert_table(out)
	assert_nil(message)
	assert_equal(valid['one'], out['one'])
	assert_equal(valid['two'], out['two'])
	assert_equal(valid['three'], out['three'])
	
	out, message = subhash:fill(invalid)
	assert_nil(out)
	assert_string(message)

end


--
-- Test that filling something below a hash gets validated.
--
function test_fill_hash_recursive_class_invalid()

	local invalid_1 = {
		string_field = "thing",
		number_field = true
		}

	local invalid_2 = {
		string_field = true,
		number_field = 242
		}

	local invalid_3 = {
		string_field = 3533,
		number_field = function() end
		}

	local out, message = xtype:fill( { hash3 = { thing = invalid_1 } } )
	assert_nil(out)
	assert_string(message)
	
	out, message = xtype:fill( { hash3 = { thing = invalid_2 } } )
	assert_nil(out)
	assert_string(message)
	
	out, message = xtype:fill( { hash3 = { thing = invalid_3 } } )
	assert_nil(out)
	assert_string(message)

end


lunatest.run()
