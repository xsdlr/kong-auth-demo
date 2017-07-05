local http = require "socket.http"
local ltn12 = require "ltn12"
local cjson = require "cjson.safe"

local BasePlugin = require "kong.plugins.base_plugin"
local responses = require "kong.tools.responses"

local TokenAuthHandler = BasePlugin:extend()

TokenAuthHandler.PRIORITY = 1000
--- Get auth header field from headers
-- @param request       request
-- @param conf          plugin configuration
-- @return auth_header  request headers for auth
local function extract_auth_field(request, conf)
  local auth_header_field = {}
  local auth_key_names = conf.auth_key_names
  local req_headers = request.get_headers()

  for i=1, #auth_key_names do
    local key = auth_key_names[i]
    auth_header_field[key] = req_headers[key]
  end

  return auth_header_field
end

--- Query auth server to validate token
-- @param headers           request headers
-- @param conf              plugin configuration
-- @return is_validate      token is validate
-- @return code             response status code
-- @return response_headers response headers
-- @return res              response body
local function validate_token (headers, conf)
  ngx.log(ngx.DEBUG, "validate token info from: ", conf.auth_server_url)
  local response_body = {}
  local res, code, response_headers = http.request{
    url = conf.auth_server_url,
    method = "GET",
    headers = headers,
    sink = ltn12.sink.table(response_body),
  }
  if code == 204 then
    return true
  end
  local resp
  if type(response_body) ~= "table" then
    resp = response_body
  else
    resp = table.concat(response_body)
  end
  ngx.log(ngx.DEBUG, "response body: ", resp)
  local decoded, err = cjson.decode(resp)
  if err then
    ngx.log(ngx.ERR, "failed to decode response body: ", err)
    return false, code, response_headers, {}
  end
  return false, code, response_headers, decoded
end

function TokenAuthHandler:new()
  TokenAuthHandler.super.new(self, "custom-token-auth")
end

function TokenAuthHandler:access(conf)
  TokenAuthHandler.super.access(self)
  local is_options_request = ngx.req.get_method == ngx.HTTP_OPTIONS
  if not is_options_request then
    local auth_header_field, err = extract_auth_field(ngx.req, conf)
    local is_validate, code, response_headers, response = validate_token(auth_header_field, conf)
    if not is_validate then
      local response_status_code = code
      if response_status_code >= 500 then
        response_status_code = 401
      end
      return responses.send(response_status_code, response, response_headers)
    end
  end
end

return TokenAuthHandler