local led = 2

gpio.config({ gpio = led, dir = gpio.IN_OUT })

-- local timer = tmr.create()

-- timer:register(1000, tmr.ALARM_AUTO, function()
--   gpio.write(led, bit.bxor(gpio.read(led), 1))
-- end)

-- timer:start()

wifi.mode(wifi.STATION)
wifi.start()
wifi.sta.sethostname("ESP32#2")

srv = net.createServer(net.TCP, 15)

local statusText = {}

statusText[200] = "OK"
statusText[204] = "No Content"
statusText[404] = "Not Found"

local mimeTypes = {
  html='text/html',
  js='text/javascript',
  ico='image/vnd.microsoft.icon'
}

local files = file.list()

local function sendHeader(sck, status, type, length)
  sck:send("HTTP/1.1 " .. tostring(status) .. " " .. statusText[status] .. "\r\n")
  -- sck:send("Connection: close\r\n")
  sck:send("X-Powered-By: nodemcu\r\n")

  if status == 200 then
    sck:send("Content-Length: " .. length .. "\r\n")
    sck:send("Content-Type: " .. type .. "\r\n")
  elseif status == 404 then
    sck:send("Content-Length: 0\r\n")
  end

  sck:send("\r\n")
end

local function sendFile(sck, path)
  local fd = file.open(path, 'r')

  local function send(localSocket)
    local s = fd:read()
    if s then
      print(sck, #s)
      localSocket:send(s)
      -- coroutine.yield()
    else
      localSocket:close()
      fd:close()
    end
  end

  sck:on('sent', send);

  send(sck);


  -- repeat
  --   local s = fd:read()
  --   if s then
  --     print(sck, #s)
  --     sck:send(s)
  --     -- coroutine.yield()
  --   end
  -- until not s
  -- fd:close()
end

function receiver(sck, req)

  local function onSent(localSocket)
    print('in sent')
  end

  sck:on("sent", onSent)

  print(req)
  print(sck)
  local _, _, method, path = string.find(req, "^(%w+) /(.*) HTTP/1\.1")

  if path == '' then
    path = 'index.html'
  end

  if path == 'api/led' then
    if method == 'GET' then
      local s = tostring(gpio.read(led))
      sendHeader(sck, 200, 'text/plain', #s)
      sck:send(s)
    elseif method == 'POST' then
      gpio.write(led, bit.bxor(gpio.read(led), 1))
      sendHeader(sck, 204)
    end
  elseif path == 'api/node' then
    local s = node.chipid()
    s = s .. ',' .. tostring(node.uptime())
    s = s .. ',' .. tostring(node.heap())
    sendHeader(sck, 200, 'text/plain', #s)
    sck:send(s)
  elseif path and file.exists(path) then
    local ext = string.match(path, '%.([^.]+)$')
    sendHeader(sck, 200, mimeTypes[ext], files[path])
    local cr = coroutine.create(sendFile)
    coroutine.resume(cr, sck, path)
  else
    sendHeader(sck, 404)
  end
end

if srv then
  -- local cr = {}
  -- local crIndex = 0

  srv:listen(80, function(conn)
    conn:on("receive", receiver)
  end)
end
