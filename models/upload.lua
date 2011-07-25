--- A basic lower upload API
--
module(..., package.seeall)

require 'posix'
local Model = require 'bamboo.model'
local Form = require 'bamboo.form'



local function calcNewFilename(dest_dir, oldname)
	-- separate the base name and extense name of a filename
	local main, ext = oldname:match('^(.+)(%.%w+)$')
	if not ext then 
		main = oldname
		ext = ''
	end
	-- check if exists the same name file
	local tstr = ''
	local i = 0
	while posix.stat( dest_dir + main + tstr + ext ) do
		i = i + 1
		tstr = '_' + tostring(i)
	end
	-- concat to new filename
	local newbasename = main + tstr

	return newbasename, ext
end

--- here, we temprorily only consider the file data is passed wholly by zeromq
-- and save by bamboo
-- @field t.req 
-- @field t.file_obj
-- @field t.dest_dir
-- @field t.prefix
-- @field t.postfix
-- 
local function savefile(t)
	local req, file_obj = t.req, t.file_obj
	local monserver_dir = bamboo.config.monserver_dir
	local project_name = bamboo.config.project_name
	assert(monserver_dir)
	assert(project_name)
	local dest_dir = (t.dest_dir and monserver_dir + '/sites/' + project_name + '/uploads/' + t.dest_dir)
	dest_dir = string.trailingPath(dest_dir)
	local url_prefix = 'media/uploads/' + t.dest_dir + '/'
	url_prefix = string.trailingPath(url_prefix)
	local prefix = t.prefix or ''
	local postfix = t.postfix or ''
	local filename = ''
	local body = ''
	
	-- if upload in html5 way
	if req.headers['x-requested-with'] then
		-- when html5 upload, we think of the name of that file was stored in header x-file-name
		-- if this info missing, we may consider the filename was put in the query string
		filename = req.headers['x-file-name']
		-- TODO:
		-- req.body contains all file binary data
		body = req.body
	else
		checkType(file_obj, 'table')
		-- Notice: the filename in the form string are quoted by ""
		-- this pattern rule can deal with the windows style directory delimiter
		-- file_obj['content-disposition'] contains many file associated info
		filename = file_obj['content-disposition'].filename:sub(2, -2):match('\\?([^\\]-%.%w+)$')

		body = file_obj.body
	end
	if isFalse(filename) or isFalse(body) then return nil, nil end
	
	if not posix.stat(dest_dir) then
		-- why posix have no command like " mkdir -p "
		os.execute('mkdir -p ' + dest_dir)
	end

	local newbasename, ext = calcNewFilename(dest_dir, filename)

	local newname = prefix + newbasename + postfix + ext
	local disk_path = dest_dir + newname
	local url_path = url_prefix + newname

	-- write file to disk
	local fd = io.open(disk_path, "wb")
	fd:write(body)
	fd:close()
	
	return disk_path, newname, url_path
end



local Upload = Model:extend {
	__tag = 'Bamboo.Model.Upload';
	__name = 'Upload';
	__desc = "User's upload files.";
	__fields = {
		['name'] = {},
		['path'] = {},
		['size'] = {},
		['timestamp'] = {},
		['desc'] = {},
		
	};
	
	init = function (self, t)
		if not t then return self end
		
		self.name = t.name or self.name
		self.path = t.url_path
		self.size = posix.stat(t.path).size
		self.timestamp = os.time()
		-- according the current design, desc field is nil
		self.desc = t.desc or ''
		
		return self
	end;
	
	--- For traditional Html4 form upload 
	-- 
	batch = function (self, req, params, dest_dir, prefix, postfix)
		I_AM_CLASS(self)
		local file_objs = List()
		-- file data are stored as arraies in params
		for i, v in ipairs(params) do
			local path, name, url_path = savefile { req = req, file_obj = v, dest_dir = dest_dir, prefix = prefix, postfix = postfix }
			if not path or not name then return nil end
			-- create file instance
			local file_instance = self { name = name, path = path, url_path = url_path }
			if file_instance then
				-- store to db
				file_instance:save()
				file_objs:append(file_instance)
			end
		end
		
		-- a file object list
		return file_objs	
	end;
	
	process = function (self, web, req, dest_dir, prefix, postfix)
		I_AM_CLASS(self)
		assert(web, '[ERROR] Upload input parameter: "web" must be not nil.')
		assert(req, '[ERROR] Upload input parameter: "req" must be not nil.')
		-- current scheme: for those larger than PRESIZE, send a ABORT signal, and abort immediately
		if req.headers['x-mongrel2-upload-start'] then
			print('return blank to abort upload.')
			web.conn:reply(req, '')
			return nil, 'Uploading file is too large.'
		end

	    -- if upload in html5 way
	    if req.headers['x-requested-with'] then
			-- stored to disk
			local path, name, url_path = savefile { req = req, dest_dir = dest_dir, prefix = prefix, postfix = postfix }    
			if not path or not name then return nil, '[ERROR] empty file.' end
			
			local file_instance = self { name = name, path = path, url_path = url_path }
			if file_instance then
				file_instance:save()
				return file_instance, 'single'
			end
		else
		-- for uploading in html4 way
			local params = Form:parse(req)
			local files = self:batch ( req, params, dest_dir, prefix, postfix )
			if not files then return nil, '[ERROR] empty file.' end
			
			if #files == 1 then
				-- even only one file upload, batch function will return a list
				return files[1], 'single'
			else
				return files, 'multiple'
			end
		end
	
	end;
	
	calcNewFilename = function (self, dest_dir, oldname)
		return calcNewFilename(dest_dir, oldname)
	end;
	
	-- this function, encorage override by child model, to execute their own delete action
	specDelete = function (self)
		I_AM_INSTANCE()
		-- remove file from disk
		os.execute('mkdir -p ' + self.path)
		return self
	end;
	
}

return Upload


