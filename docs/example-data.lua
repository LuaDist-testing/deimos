#!/usr/local/bin/lua

return {

		["example.com"] = {
				aliases = { "www.example.com", "www2.example.com" }
			},
			
		["ssl.example.com"] = {
				ssl = 8088
			},
			
		["employees.example.com"] = {
				aliases = { "www.employees.example.com" }
			},
			
		["users.example.com"] = {
				aliases = { "user1.example.com", "user2.example.com" },
				ssl = 8089,
				ssl_wildcard = true
			},
			
		["oldsite.example.com"] = {
				extras = [[
					RewriteEngine on
					RedirectMatch .*  http://example.com  permanent
				]]
			}
		
	}
