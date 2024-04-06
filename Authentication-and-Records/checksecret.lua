local redis = require("resty.redis")

local json = require("cjson")

local http = require("resty.http")

local secret_pass = true


local function close_redes( red )
  if not red then
    return
  end
  local ok, err = red:close()
  if not ok then
    ngx.say("close redis error:", err)
  end
end


local function record_secret(apikey)
  local req_uri = ngx.var.request_uri

  local client_ip = ngx.var.remote_addr

  local httpc = http.new()

  httpc:set_timeout(2000)

  local remote_res, err = httpc:request_uri(
      "http://127.0.0.1:18882/record_secret",
      {
      method = "POST",
      body = json.encode({client_ip=client_ip, url=req_uri, apikey=apikey}),
      }
  )

  if remote_res == nil then
      ngx.status = ngx.HTTP_BAD_GATEWAY
      ngx.log(ngx.ERR, " record_secret:", err)
      ngx.say(json.encode({msg="Server Error, please contact the system administrator."}))
  else
      if 200 ~= remote_res.status then
          ngx.status = ngx.HTTP_BAD_GATEWAY
          ngx.log(ngx.ERR, " record_secret status err:", remote_res.status)
          ngx.say(json.encode({msg="Server Error, please contact the system administrator."}))
      end
  end

end



-- 创建实例
local red = redis:new()
-- 设置超时(毫秒)
red:set_timeout(2000)
-- 建立连接
local ip = "127.0.0.1"
local port = 6379
local ok, err = red:connect(ip, port)
if not ok then
  ngx.status = ngx.HTTP_BAD_GATEWAY
  ngx.log(ngx.ERR, " redis connect error:", err)
  ngx.say(json.encode({msg="Server Error, please contact the system administrator."}))
  return
end

local res, err = red:auth("changepassword")
if not res then
  ngx.status = ngx.HTTP_BAD_GATEWAY
  ngx.log(ngx.ERR, " redis auth error:", err)
  ngx.say(json.encode({msg="Server Error, please contact the system administrator."}))
  return
end

-- web apikey
local headers = ngx.req.get_headers()

local apikey = headers.apikey
if apikey == nil then
    ngx.status = ngx.HTTP_UNAUTHORIZED
    ngx.log(ngx.ERR, " header apikey doesn't exist.")
    ngx.say(json.encode({msg="Authentication failed, please contact the system administrator."}))
    return close_redes(red)
end

red:select(1)

-- 调用API获取数据
local resp, err = red:get(apikey)
if not resp then
  secret_pass = false
  ngx.status = ngx.HTTP_UNAUTHORIZED
  ngx.log(ngx.ERR, " redis apikey doesn't exist.")
  ngx.say(json.encode({msg="Authentication failed, please contact the system administrator."}))
  return close_redes(red)
end

-- 得到数据为空处理
if resp == ngx.null then
  secret_pass = false
  ngx.status = ngx.HTTP_UNAUTHORIZED
  ngx.log(ngx.ERR, " redis apikey doesn't exist.")
  ngx.say(json.encode({msg="Authentication failed, please contact the system administrator."}))
end

close_redes(red)


if secret_pass == true then
  record_secret(apikey)
end
