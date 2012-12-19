
local dbsnippets = bamboo.dbsnippets

SNIPPET_logicMethods = 
[=[
local LOGIC_METHODS = {}
LOGIC_METHODS.eq = function ( cmp_obj )
	return function (v)
		if v == cmp_obj then
			return true
		else
			return false
		end
	end
end

LOGIC_METHODS.uneq = function ( cmp_obj )
	return function (v)
		if v ~= cmp_obj then
			return true
		else
			return false
		end
	end
end

LOGIC_METHODS.lt = function (limitation)
	return function (v)
		if v and v < limitation then
			return true
		else
			return false
		end
	end
end

LOGIC_METHODS.gt = function (limitation)
	return function (v)
		if v and v > limitation then
			return true
		else
			return false
		end
	end
end

LOGIC_METHODS.le = function (limitation)
	return function (v)
		if v and v <= limitation then
			return true
		else
			return false
		end
	end
end

LOGIC_METHODS.ge = function (limitation)
	return function (v)
		if v and v >= limitation then
			return true
		else
			return false
		end
	end
end

LOGIC_METHODS.bt = function (small, big)
	return function (v)
		if v and v > small and v < big then
			return true
		else
			return false
		end
	end
end

LOGIC_METHODS.be = function (small, big)
	return function (v)
		if v and v >= small and v <= big then
			return true
		else
			return false
		end
	end
end

LOGIC_METHODS.outside = function (small, big)
	return function (v)
		if v and (v < small or v > big) then
			return true
		else
			return false
		end
	end
end

LOGIC_METHODS.contains = function (substr)
	return function (v)
		v = tostring(v)
		if v:find(substr) then
			return true
		else
			return false
		end
	end
end

LOGIC_METHODS.uncontains = function (substr)
	return function (v)
		v = tostring(v)
		if not v:find(substr) then
			return true
		else
			return false
		end
	end
end

LOGIC_METHODS.startsWith = function (substr)
	return function (v)
		v = tostring(v)
		if v:find('^'..substr) then
			return true
		else
			return false
		end
	end
end

LOGIC_METHODS.unstartsWith = function (substr)
	return function (v)
		v = tostring(v)
		if not v:find('^'..substr) then
			return true
		else
			return false
		end
	end
end


LOGIC_METHODS.endsWith = function (substr)
	return function (v)
		v = tostring(v)
		if v:find(substr..'$') then
			return true
		else
			return false
		end
	end
end

LOGIC_METHODS.unendsWith = function (substr)
	return function (v)
		v = tostring(v)
		if not v:find(substr..'$') then
			return true
		else
			return false
		end
	end
end

LOGIC_METHODS.inset = function (args)
	return function (v)
		v = tostring(v)
		for _, val in ipairs(args) do
			-- once meet one, ok
			if tostring(val) == v then
				return true
			end
		end

		return false
	end
end

LOGIC_METHODS.uninset = function (args)
	local t = function (v)
		v = tostring(v)
		for _, val in ipairs(args) do
			-- once meet one, false
			if tostring(val) == v then
				return false
			end
		end

		return true
	end
	return t
end

]=]



local SNIPPET_stringSplit = 
[[
function string.split(str, pat)
   local t = {}
   local fpat = "(.-)" .. pat
   local last_end = 1
   local s, e, cap = str:find(fpat, 1)
   while s do
      if s ~= 1 or cap ~= "" then
      		table.insert(t,cap)
      end
      last_end = e+1
      s, e, cap = str:find(fpat, last_end)
   end
   if last_end <= #str then
      cap = str:sub(last_end)
      table.insert(t, cap)
   end
   return t
end
	 
]]

local SNIPPET_deserializeQueryFunction = 
[[

local deserializeQueryFunction = function (qstr)
	local query_func

	if qstr:match('^function') then
		local parts = qstr:split(' ^_^ ')
		local func_part = parts[2]
		-- now fpart is the function binary string
		query_func = loadstring(func_part)

		if #parts > 2 then
			local j = 0
			for i=3, #parts, 3 do
				local key = parts[i]
				local value = parts[i+1]
				local vtype = parts[i+2]
				
				if vtype == 'table' then
					value = (value)
				elseif vtype == 'number' then
					value = tonumber(value)
				elseif vtype == 'boolean' then
					value = value == 'true'
				elseif vtype == 'nil' then
					value = nil
				end

				j = j + 1
				-- set upvalues
				debug.setupvalue(query_func, j, value)
			end
		end
	end

	return query_func
end
]]



dbsnippets.set.SNIPPET_hgetallByModelIds = 
[=[
local modelids_string = unpack(ARGV);								 
local modelids = cmsgpack.unpack(modelids_string)
local obj_list = {}
for i, key in ipairs(modelids) do
	local obj = redis.call('HGETALL', key)
	table.insert(obj_list, obj)
end

-- here, obj_list is the form of 
-- {{key1, val1, key2, val2}, {key1, val1, key2, val2}, {...}}
return obj_list
]=]

dbsnippets.set.SNIPPET_hmgetByIdsFields = 
[=[
local model_name, ids_string, fields_string = unpack(ARGV);								 
local ids = cmsgpack.unpack(ids_string)
local fields = cmsgpack.unpack(fields_string)
local obj_list = {}
for i, id in ipairs(ids) do
	local key = ('%s:%s'):format(model_name, id)
	local obj = redis.call('HMGET', key, unpack(fields))
	table.insert(obj_list, obj)
end

-- here, obj_list is the form of 
-- {{key1, val1, key2, val2}, {key1, val1, key2, val2}, {...}}
return obj_list
]=]

dbsnippets.set.SNIPPET_delInstanceAndForeigns = 
[=[
local model_name, id, fields_string = unpack(ARGV);								 
local fields = cmsgpack.unpack(fields_string)
local index_key = string.format('%s:%s', model_name, '__index')
local instance_key = string.format('%s:%s', model_name, id)
local foreign_key
for k, fld in pairs(fields) do
	if fld and fld.foreign then
		foreign_key = string.format('%s:%s', instance_key, k)
		redis.call('DEL', foreign_key)
	end
end

redis.call('DEL', instance_key)
redis.call('ZREMRANGEBYSCORE', index_key, id, id)
]=]

dbsnippets.set.SNIPPET_fakeDelInstanceAndForeigns = 
[=[
local model_name, id, fields_string, rubpot_key = unpack(ARGV);								 
local fields = cmsgpack.unpack(fields_string)
local index_key = string.format('%s:%s', model_name, '__index')
local instance_key = string.format('%s:%s', model_name, id)
local foreign_key
for k, fld in pairs(fields) do
	if fld and fld.foreign then
		foreign_key = string.format('%s:%s', instance_key, k)
		if redis.call('EXISTS', foreign_key) then
			redis.call('RENAME', foreign_key, 'DELETED:' .. foreign_key)
		end

	end
end

redis.call('RENAME', instance_key, 'DELETED:' .. instance_key)
redis.call('ZREMRANGEBYSCORE', index_key, id, id)
local n = redis.call('ZCARD', rubpot_key)
redis.call('ZADD', rubpot_key, n+1, instance_key)

]=]

dbsnippets.set.SNIPPET_getById = 
[[
local model_name, id = unpack(ARGV)
local key = string.format('%s:%s', model_name, id)
if not redis.call('EXISTS', key) then return false end
return redis.call('HGETALL', key)
]]

dbsnippets.set.SNIPPET_getByIds = 
[=[
local model_name, ids_string = unpack(ARGV);								 
local ids = cmsgpack.unpack(ids_string)

local obj_list = {}
for i, id in ipairs(ids) do
	local key = ('%s:%s'):format(model_name, id)
	local obj = redis.call('HGETALL', key)
	table.insert(obj_list, obj)
end

-- here, obj_list is the form of 
-- {{key1, val1, key2, val2}, {key1, val1, key2, val2}, {...}}
return obj_list

]=]


dbsnippets.set.SNIPPET_getByIdWithForeigns = 
[=[
local model_name, id, ffields_str = unpack(ARGV)
local key = string.format('%s:%s', model_name, id)
local ffields = cmsgpack.unpack(ffields_str)

if not redis.call('EXIST', key) then return false end
local data = redis.call('HGETALL', key)
local hash_data = {}
for i=1, #data do
	hash_data[data[i]] = data[i+1]
end

for field, fdt in pairs(ffields) do
	local value = hash_data[field]
	local foreign_type = fdt.foreign
	local store_type = fdt.st
	local fkey = string.format('%s:%s', key, field)

	-- for ONE case
	if value then
		if store_type == 'UNFIXED' then
			hash_data[field] = redis.call('HGETALL', value)
		elseif store_type ~= 'ANYSTRING' then
			local target_key = string.format('%s:%s', foreign_type, value)
			hash_data[field] = redis.call('HGETALL', target_key)
		end
	else
		if sotre_type == 'MANY' or store_type = 'ZFIFO' then
			hash_data[field] = redis.call('ZRANGE', fkey, 0, -1)
		elseif sotre_type == 'LIST' or store_type = 'FIFO' then
			hash_data[field] = redis.call('LRANGE', fkey, 0, -1)
		end
	end
end

local r_data = {}
for k, v in pairs(hash_data) do
	table.insert(r_data, k)
	table.insert(r_data, v)
end

return r_data
]=]

dbsnippets.set.SNIPPET_getByIdsWithForeigns = 
[=[
local model_name, ids_str, ffields_str = unpack(ARGV)
local ids = cmsgpack.unpack(ids_str)
local ffields = cmsgpack.unpack(ffields_str)

local r_data = {}
for _, id in ipairs(ids) do
	local key = string.format('%s:%s', model_name, id)
	if redis.call('EXISTS', key) then
		local data = redis.call('HGETALL', key)
		local hash_data = {}
		for i=1, #data do
			hash_data[data[i]] = data[i+1]
		end

		for field, fdt in pairs(ffields) do
			local value = hash_data[field]
			local fkey = string.format('%s:%s', key, field)
			local foreign_type = fdt.foreign
			local store_type = fdt.st

			-- for ONE case
			if value then
				
				if store_type == 'UNFIXED' then
					hash_data[field] = redis.call('HGETALL', value)
				elseif store_type ~= 'ANYSTRING' then
					local target_key = string.format('%s:%s', foreign_type, value)
					hash_data[field] = redis.call('HGETALL', target_key)
				end
			else
				if sotre_type == 'MANY' or store_type = 'ZFIFO' then
					hash_data[field] = redis.call('ZRANGE', fkey, 0, -1)
				elseif sotre_type == 'LIST' or store_type = 'FIFO' then
					hash_data[field] = redis.call('LRANGE', fkey, 0, -1)
				end
			end
		end
	end

	local r_obj = {}
	for k, v in pairs(hash_data) do
		table.insert(r_obj, k)
		table.insert(r_obj, v)
	end

	table.insert(r_data, r_obj)
end

return r_data
]=]


dbsnippets.set.SNIPPET_all = 
[=[
local model_name, is_rev = unpack(ARGV)
local index_key = string.format('%s:__index', model_name)
local r
if is_rev == 'rev' then
	r = redis.call('ZREVRANGE', index_key, 0, -1, 'withscores')
else
	r = redis.call('ZRANGE', index_key, 0, -1, 'withscores')
end
	 
local ids = {}
for i = 1, #r, 2 do
	table.insert(ids, r[i+1])
end

local obj_list = {}
for i, id in ipairs(ids) do
	local key = ('%s:%s'):format(model_name, id)
	local obj = redis.call('HGETALL', key)
	table.insert(obj_list, obj)
end

-- here, obj_list is the form of 
-- {{key1, val1, key2, val2}, {key1, val1, key2, val2}, {...}}
return obj_list

]=]

dbsnippets.set.SNIPPET_slice = 
[=[
local model_name, istart, istop, is_rev = unpack(ARGV)
local index_key = string.format('%s:__index', model_name)
local r
r = redis.call('ZRANGE', index_key, istart, istop, 'withscores')

local ids = {}
if is_rev == 'rev' then
	for i = #r, 1, -2 do
		table.insert(ids, r[i])
	end
else
	for i = 1, #r, 2 do
		table.insert(ids, r[i+1])
	end
end

local obj_list = {}
for i, id in ipairs(ids) do
	local key = ('%s:%s'):format(model_name, id)
	local obj = redis.call('HGETALL', key)
	table.insert(obj_list, obj)
end

-- here, obj_list is the form of 
-- {{key1, val1, key2, val2}, {key1, val1, key2, val2}, {...}}
return obj_list

]=]

dbsnippets.set.SNIPPET_save = 
[[
local model_name, id, primarykey, params_str = unpack(ARGV)
local index_key = string.format('%s:__index', model_name)
local params = cmsgpack.unpack(params_str)
local new_case
-- if self has id attribute, it is an instance saved before. use id to separate two cases
if id == '' then 
	new_case = true
else
	new_case = false 
end

local key
local countername = string.format("%s:__counter", model_name)
local new_primary = params[primarykey]

if new_case then
	local new_id = redis.call('INCR', countername)
	if new_primary then
		local already_at = redis.call('ZSCORE', index_key, new_primary)
		if already_at then return false end
		redis.call('ZADD', index_key, new_id, new_primary)
	else
		redis.call('ZADD', index_key, new_id, new_id)
	end

	local store_kv = {
		'id', new_id
	}
	for k, v in pairs(params) do
		table.insert(store_kv, k)
		table.insert(store_kv, v)
	end
	
	key = string.format('%s:%s', model_name, new_id)

	redis.call('HMSET', key, unpack(store_kv))
	id = new_id
else
	local counter = redis.call('GET', countername)
	if tonumber(id) > tonumber(counter) then return false end

	-- if primarykey is id, new_primary is nil
	if new_primary then
		local score = redis.call('ZSCORE', index_key, new_primary)
		if score and tostring(score) ~= id then return false end
		redis.call('ZREMRANGEBYSCORE', index_key, id, id)
		redis.call('ZADD', index_key, id, new_primary)
	end

	local store_kv = {}
	for k, v in pairs(params) do
		table.insert(store_kv, k)
		table.insert(store_kv, v)
	end

	key = string.format('%s:%s', model_name, id)
	redis.call('HMSET', key, unpack(store_kv))

end

return id
]]

dbsnippets.set.SNIPPET_update = 
[[
local model_name, id, primarykey, field, new_value, lmtime = unpack(ARGV)
local key = string.format('%s:%s', model_name, id)
local index_key = string.format('%s:__index', model_name)
if not redis.call('EXISTS', key) then return false end
if field == primarykey then
	if new_value == '' then return false end
	redis.call('ZREMRANGEBYSCORE', index_key, id, id)
	redis.call('ZADD', index_key, id, new_value)
end

if new_value == '' then
	redis.call('HDEL', key, field)
else
	redis.call('HSET', key, field, new_value)
end

redis.call('HSET', key, 'lastmodified_time', lmtime)

return true
]]

dbsnippets.set.SNIPPET_addForeign = 
[[
local model_name, id, field, new_id, fdt_str = unpack(ARGV)
local fdt = cmsgpack.unpack(fdt_str)
local slen = fdt.fifolen or 100
local foreign_type = fdt.foreign
local store_type = fdt.st
local key = string.format('%s:%s', model_name, id)
local fkey = string.format('%s:%s:%s', model_name, id, field)

if store_type == 'ONE' then
	-- record in db
	redis.call('HSET', key, field, new_id)

elseif store_type == 'MANY' then
	-- for MANY,  
	redis.call('ZADD', fkey, os.time(), new_id)

elseif store_type == 'FIFO' then
	local len = redis.call('LLEN', fkey)
	local slen = fdt.fifolen or 100
	if len >= slen then
		-- if FIFO is full, push this element from right, pop one old from left
		redis.call('LPOP', fkey)
	end
	redis.call('RPUSH', fkey, new_id)

elseif store_type == 'ZFIFO' then
	local n = redis.call('ZCARD', fkey)
	redis.call('ZADD', fkey, n+1, new_id)
	local nn = redis.call('ZCARD', fkey)
	if nn > slen then
		-- remove the oldest one
		redis.call('ZREMRANGEBYRANK', fkey, 0, 0)
	end

elseif store_type == 'LIST' then
	redis.call('RPUSH', fkey, new_id)
end

redis.call('HSET', key, 'lastmodified_time', os.time())
]]


dbsnippets.set.SNIPPET_getForeign = 
[[
-- here, start and stop is the transformed location index for redis, not lua
local model_name, id, field, fdt_str, start, stop, is_rev, onlyids = unpack(ARGV)

local fdt = cmsgpack.unpack(fdt_str)
local slen = fdt.fifolen or 100
local foreign_type = fdt.foreign
local store_type = fdt.st
local key = string.format('%s:%s', model_name, id)
local fkey = string.format('%s:%s:%s', model_name, id, field)

local r_data = {}
if store_type == 'MANY' or store_type == 'ZFIFO' then
	local data = redis.call('ZRANGE', fkey, start, stop)

	if is_rev == 'rev' then
		for i = #data, 1, -1 do
			table.insert(r_data, data[i])
		end
	else
		for i = 1, #data do
			table.insert(r_data, data[i])
		end
	end

elseif store_type == 'LIST' or store_type == 'FIFO' then
	local data = redis.call('LRANGE', fkey, start, stop)

	if is_rev == 'rev' then
		for i = #data, 1, -1 do
			table.insert(r_data, data[i])
		end
	else
		r_data = data
	end
end

if onlyids == 'onlyids' then return r_data end

local objs = {}
if foreign_type == 'ANYSTRING' then	return r_data end
if foreign_type == 'UNFIXED' then 
	for i, id in ipairs(ids) do
		table.insert(objs, redis.call('HGETALL', id))
	end
	return objs
end

-- the normal case
for i, id in ipairs(ids) do
	local okey = string.format('%s:%s', foreign_type, id)
	table.insert(objs, redis.call('HGETALL', okey))
end

return objs
]]




dbsnippets.set.SNIPPET_get = 
[=[
${logicMethods}
${stringSplit}
${deserializeQueryFunction}

local model_name, fields_string, query_type, query_string, logic = unpack(ARGV)
local is_rev = ''
local fields = cmsgpack.unpack(fields_string)
local query_args
if query_type == 'table' then
	query_args = cmsgpack.unpack(query_string)
elseif query_type == 'function' then
	query_args = deserializeQueryFunction(query_string)
else 
	query_args = query_string
end

local PARTLEN = 1024
local logic_choice = logic == 'and'
local flag = logic_choice
local index_key = string.format('%s:__index', model_name)
local length = redis.call('ZCARD', index_key)

if query_type == 'table' then
	for j = 0, length-1, PARTLEN do
		local r
		if is_rev == 'rev' then
			r = redis.call('ZREVRANGE', index_key, j, j+PARTLEN-1, 'WITHSCORES')
		else
			r = redis.call('ZRANGE', index_key, j, j+PARTLEN-1, 'WITHSCORES')
		end

		local methods = {}
		for k, v in pairs(query_args) do
			if type(v) == 'table' then
				local method = table.remove(v, 1)
				methods[k] = method
			end
		end

		for i = 1, #r, 2 do
			local id = r[i+1]
			local key = ('%s:%s'):format(model_name, id)
			local obj = redis.call('HGETALL', key)

			local hash_data = {}
			for ii = 1, #obj, 2 do
				hash_data[obj[ii]] = obj[ii+1]
			end

			for k, v in pairs(query_args) do
				-- to redundant query condition, once meet, jump immediately
				if not fields[k] then return false end

				-- it uses a logic function
				if type(v) == 'table' then

					flag = LOGIC_METHODS[methods[k]](unpack(v))(hash_data[k])
				else
					flag = (hash_data[k] == v)
				end

				---------------------------------------------------------------
				-- logic_choice,       flag,      action,          append?
				---------------------------------------------------------------
				-- true (and)          true       next field       --
				-- true (and)          false      break            no
				-- false (or)          true       break            yes
				-- false (or)          false      next field       --
				---------------------------------------------------------------
				if logic_choice ~= flag then break end
			end

			if flag then return obj end
		end
	end
elseif query_type == 'function' then
	for j = 0, length-1, PARTLEN do
		local r
		if is_rev == 'rev' then
			r = redis.call('ZREVRANGE', index_key, j, j+PARTLEN-1, 'WITHSCORES')
		else
			r = redis.call('ZRANGE', index_key, j, j+PARTLEN-1, 'WITHSCORES')
		end

		for i = 1, #r, 2 do
			local id = r[i+1]
			local key = ('%s:%s'):format(model_name, id)
			local obj = redis.call('HGETALL', key)

			local hash_data = {}
			for ii = 1, #obj, 2 do
				hash_data[obj[ii]] = obj[ii+1]
			end
			
			local flag = query_args(hash_data)
			if flag then return obj end
		end
	end
elseif query_type == 'string' then
		-- TODO
end

redis.log(redis.LOG_WARNING, '4---')

]=] % {
	logicMethods = SNIPPET_logicMethods,
	stringSplit = SNIPPET_stringSplit, 
	deserializeQueryFunction = SNIPPET_deserializeQueryFunction
}



dbsnippets.set.SNIPPET_filter = 
[=[

${logicMethods}
${stringSplit}
${deserializeQueryFunction}


local model_name, fields_string, query_type, query_string, logic = unpack(ARGV)
local fields = cmsgpack.unpack(query_string)
local query_args
if query_type == 'table' then
	query_args = cmsgpack.unpack(query_string)
elseif query_type == 'function' then
	query_args = deserializeQueryFunction(query_string)
else 
	query_args = query_string
end

local logic_choice = logic == 'and'
local flag = logic_choice

local index_key = string.format('%s:__index', model_name)

local PARTLEN = 1024
local length = redis.call('ZCARD', index_key)
local objs = {}
for j = 1, length, PARTLEN do
	local r
	if is_rev == 'rev' then
		r = redis.call('ZREVRANGE', index_key, j, j+PARTLEN-1, 'WITHSCORES')
	else
		r = redis.call('ZRANGE', index_key, j, j+PARTLEN-1, 'WITHSCORES')
	end

	if query_type == 'table' then
		for i = 1, #r, 2 do
			local id = r[i+1]
			local key = ('%s:%s'):format(model_name, id)
			local obj = redis.call('HGETALL', key)

			local hash_data = {}
			for i = 1, #obj, 2 do
				hash_data[obj[i]] = obj[i+1]
			end

			for k, v in pairs(query_args) do
				-- to redundant query condition, once meet, jump immediately
				if not fields[k] then flag=false; break end

				-- it uses a logic function
				if type(v) == 'table' then
					local method = table.remove(v, 1)
					flag = LOGIC_METHODS[method](unpack(v))(hash_data[k])
				else
					flag = (hash_data[k] == v)
				end

				---------------------------------------------------------------
				-- logic_choice,       flag,      action,          append?
				---------------------------------------------------------------
				-- true (and)          true       next field       --
				-- true (and)          false      break            no
				-- false (or)          true       break            yes
				-- false (or)          false      next field       --
				---------------------------------------------------------------
				if logic_choice ~= flag then break end
			end

			if flag then table.insert(objs, obj) end
		end
	elseif query_type == 'function' then
		for i = 1, #r, 2 do
			local id = r[i+1]
			local key = ('%s:%s'):format(model_name, id)
			local obj = redis.call('HGETALL', key)

			local hash_data = {}
			for i = 1, #obj, 2 do
				hash_data[obj[i]] = obj[i+1]
			end
		
			local flag = query_args(hash_data)
			if flag then table.insert(objs, obj) end
		end
	elseif query_type == 'string' then
		-- TODO
	end
end

return objs

]=] % {
	logicMethods = SNIPPET_logicMethods,
	stringSplit = SNIPPET_stringSplit, 
	deserializeQueryFunction = SNIPPET_deserializeQueryFunction
}



--[[

local obj_list = {}
for i, id in ipairs(ids) do
	local key = ('%s:%s'):format(model_name, id)
	local obj = redis.call('HGETALL', key)
	table.insert(obj_list, obj)
end

-- here, obj_list is the form of 
-- {{key1, val1, key2, val2}, {key1, val1, key2, val2}, {...}}
return obj_list


--]]



-- redis.log(redis.LOG_WARNING, 'enter now')

