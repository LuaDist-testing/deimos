#!/usr/local/bin/lua


-- lets it run immediately after unpacking the rock
-- before install.
package.path = package.path .. ";../?.lua"


local deimos = require "deimos"


---
-- Example usage of Deimos. This is sort-of real word: The actual
-- schema has a lot of proprietary stuff. Most of that was removed to 
-- make a simple example.
--
--
-- Let's say you are building a program that manages websites, in a
-- basic LAMP stack environment. The configuration files grew and 
-- multiplied until they became a headache, so a templater was written.
-- However due to Lua's weak typing makes it easy to put in typos
-- that allow templates that cause undesired behavior, or worse.
--
-- So let's put a schema on that config file...
--


---
-- The top level of our schema is a table of websites. The site's
-- hostname is used as the key.
--
local websites = deimos.hash
	{
	---
	-- Hostname goes here. Make sure someone doesn't put in an invalid
	-- key, otherwise Apache will barf.
	--
	key = deimos.string
			{ 
			pattern = "^(%a[%a%d%-]?%a)%.)+%a[%a%d%-]?%a$" 
			},
	
	
	-- The details of the site are contained in a table with explicit
	-- keys.
	value = deimos.class
		{
		---
		-- A lot of the sites have aliases, but almost all have
		-- 'www.$domain.com' as well as 'domain.com' enabled.
		--
		aliases = deimos.array { permitted = deimos.string{} },
		
		
		---
		-- Due to a lack of IP addresses, SSL sites are all run on 
		-- different nonstandard ports between 8000 and 8200. Let's 
		-- enforce that rule.
		--
		ssl = deimos.number 
				{ 
				nullable = true, 
				minimum = 8000, 
				maximum = 8200 
				},
		
		
		---
		-- There is also a wildcard cert. Use it on this site?
		--
		ssl_wildcard = deimos.bool { default = false },
		
		
		---
		-- A fallback in case you need to do something weird, raw
		-- Apache configuration to get included.
		--
		extras = deimos.string { nullable = true }
		}
	}



--- 
-- Looks good! Now let's use it.
--
local website_data, err = websites:fill(dofile("./example-data.lua"))


---
-- Was it valid?
--
if not website_data then error(err) end


---
-- Guess so. What did it contain?
--
-- Unless you found a bug (quite possible), this script should go 
-- ahead and print the contents of example-data.lua. You can try to
-- mangle the contents therein, and try to load - and watch what
-- happens when data is invalid. It should get rejected by the
-- prior line checking for website_data.
--
--
--
-- Pay careful attention to the below. Most of the standard library
-- for Lua 5.1 doesn't work through the metaprogramming: as a result, 
-- getn(), sort(), ipairs(), pairs(), etc need to be called via object 
-- notation.
--
-- Lua 5.2 should help clean this limitation up.
--
function print_data(data) 
	for k, v in data:pairs() do

		print("----")
		print("Site: ", k)
		
		if v.ssl then
			print(">> Site has SSL on port " .. tostring(v.ssl))
			
			if v.ssl_wildcard then
				print(">> Site is using the SSL wildcard.")
			end
		end

		if v.aliases:getn() > 0 then
			print(">> Site has " .. v.aliases:getn() .. " aliases: ")
			
			for k2, v2 in v.aliases:ipairs() do
				print(">>\t" .. v2)
			end
		end
		
		if v.extras then
			print(">> Site has non-standard configuration.")
		end
	end
end


print_data(website_data)
