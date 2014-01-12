local common = {}
local module = common


ngx.log(ngx.DEBUG, "LOADED common")


local function uuid()
	local random = math.random
    local template ="xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"
    return string.gsub(template, "[xy]", function (c)
        local v = (c == "x") and random(0, 0xf) or random(8, 0xb)
        return string.format("%x", v)
    end)
end

local function uuid_headers()
	ngx.header["X-uuid"] = ngx.var.uuid
end

local function utc_now()
	return os.date("!%x", ngx.time())
end

function common.sha1(v) 
	return rstr.to_hex(ngx.sha1_bin(v))
end

function common.get_uuid() 
	return uuid()
end

function common.empty_headers()
	ngx.header["Cache-Control"] = "private, no-cache, no-cache=Set-Cookie, proxy-revalidate"
	ngx.header["Pragma"] = "no-cache"
	uuid_headers()
end

function common.pixel_headers()
	if (ngx.status == ngx.HTTP_OK) then
		ngx.header["Last-Modified"] = "Mon, 14 Oct 2013 12:00:00 GMT"
		ngx.header["Expires"] = "Mon, 14 Oct 2013 10:00:00 GMT" 
		ngx.header["Pragma"] = "no-cache"
		ngx.header["Cache-Control"] = "private, no-cache, no-cache=Set-Cookie, proxy-revalidate"
	end
	uuid_headers()
end

function common.data_access()
	local method = ngx.var.request_method
   	if (not method == ngx.HTTP_POST and not method == ngx.HTTP_PUT) then
   		ngx.status = ngx.HTTP_NOT_ALLOWED
   		return ngx.exit(ngx.HTTP_NOT_ALLOWED)
   	end
end

function common.redirect_access()
	local access = common.access_filter()
	if (access) then
		return access
	end
	 
	if not ngx.var.redirect_scheme and not ngx.var.redirect_url then
   		ngx.status = ngx.HTTP_NOT_ALLOWED
   		return ngx.exit(ngx.HTTP_NOT_ALLOWED)	
	end
end

function common.redirect_content(type)
	local t = type or ngx.HTTP_MOVED_PERMANENTLY
	local url = ngx.var.redirect_scheme .. "://" .. ngx.var.redirect_url
	if (ngx.var.query_string) then
		url = url .. "?" .. ngx.var.query_string
	end
	return ngx.redirect(url, t)
end


function common.data_headers() 
	uuid_headers()
end

function common.json_headers() 
	ngx.header.content_type = "application/json"
	ngx.header["Cache-Control"] = "private, no-cache, no-cache=Set-Cookie, proxy-revalidate"
	ngx.header["Pragma"] = "no-cache"
	uuid_headers()
end

function common.js_headers() 
	ngx.header.content_type = "text/javascript"
	ngx.header["Cache-Control"] = "private, no-cache, no-cache=Set-Cookie, proxy-revalidate"
	ngx.header["Pragma"] = "no-cache"
	uuid_headers()
end

function common.txt_headers() 
	ngx.header.content_type = "text/plain"
	ngx.header["Cache-Control"] = "private, no-cache, no-cache=Set-Cookie, proxy-revalidate"
	ngx.header["Pragma"] = "no-cache"
	uuid_headers()
end

function common.redirect_headers() 
	uuid_headers()
end

function common.track_headers()
	if (ngx.status == ngx.HTTP_OK) then			
		ngx.header["ETag"] = ngx.var.uuid
		ngx.header["Pragma"] = "no-cache"
		ngx.header["Cache-Control"] = "private, no-cache, no-cache=Set-Cookie, proxy-revalidate"
	end
	
	uuid_headers()
end

function common.access_data() 
	local method = ngx.var.request_method
   	if (not method == ngx.HTTP_POST and not method == ngx.HTTP_PUT) then
   		ngx.status = ngx.HTTP_NOT_ALLOWED
   		return ngx.exit(ngx.HTTP_NOT_ALLOWED)
   	end
end

function common.access_filter()

	ngx.log(ngx.DEBUG, "access_filter()")

	if (ngx.var.http_if_modified_since) then
   		ngx.status = ngx.HTTP_NOT_MODIFIED
    	return ngx.exit(ngx.HTTP_NOT_MODIFIED)
   	end
	   	
   	if (ngx.var.http_if_none_match) then
   		ngx.status = ngx.HTTP_NOT_MODIFIED
    	return ngx.exit(ngx.HTTP_NOT_MODIFIED)
   	end    
end

function common.empty_content() 
	ngx.status = 204
	return ngx.exit(204)
end


function common.json_content() 
	local cjson = require "cjson"
	local data = {}
	data['uuid'] = ngx.var.uuid
	if (ngx.var.id ~= '-') then
		data['id'] = ngx.var.id
	end
	local json = cjson.encode(data)
	return ngx.say(json)
end

function common.js_content()
	local cjson = require "cjson"
	local json = cjson.encode({uuid = ngx.var.uuid})
	
	local callback = ngx.req.get_uri_args()["callback"]
	if callback then
		ngx.say(callback .. "(" .. json .. ");")
	else
		ngx.say("(function(w){w[\"_" .. ngx.var.account .. "\"]=" .. json .. ";})(window);")  
	end
end

function common.txt_content()
	ngx.say("uuid:" .. ngx.var.uuid)
	if (ngx.var.id ~= '-') then
		ngx.say("id:" .. ngx.var.id)
	end
end

function common.update_content() 
	return update_shared_dicts(0)
end

-- safety net
local module_mt = {
   __newindex = (
      function (table, key, val)
         error('Attempt to write to undeclared variable "' .. key .. '"')
      end),
}

setmetatable(module, module_mt)

-- expose the module
return common
