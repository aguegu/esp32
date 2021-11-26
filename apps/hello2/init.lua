local led = 2
gpio.config({ gpio = led, dir = gpio.IN_OUT })

local statusText = {}

statusText[200] = "OK"
statusText[204] = "No Content"
statusText[404] = "Not Found"

local mimeTypes = {
  html='text/html',
  js='text/javascript',
  ico='image/vnd.microsoft.icon'
}

wifi.mode(wifi.STATION)
wifi.start()
wifi.sta.sethostname("ESP32#2")

srv = net.createServer(net.TCP)

local function genHeader(status, type, length)
  local header = {
    "HTTP/1.1 " .. tostring(status) .. " " .. statusText[status] .. "\r\n",
    "Connection: close\r\n",
    "X-Powered-By: nodemcu\r\n",
  }
  if status == 200 then
    table.insert(header, "Content-Length: " .. length .. "\r\n")
    table.insert(header, "Content-Type: " .. type .. "\r\n")
  elseif status == 404 then
    table.insert(header, "Content-Length: 0\r\n")
  end

  table.insert(header, "\r\n")
  return header
end

local files = file.list()

srv:listen(80, function(conn)
  conn:on("receive", function (sck, req)
    print(req)
    print(sck)

    local _, _, method, path = string.find(req, "^(%w+) /(.*) HTTP/1\.1")
    local response = {}

    if path == '' then
      path = 'index.html'
    end

    if path == 'api/led' then
      if method == 'GET' then
        local s = tostring(gpio.read(led))
        response = genHeader(200, 'text/plain', #s)
        table.insert(response, s)
      elseif method == 'POST' then
        gpio.write(led, bit.bxor(gpio.read(led), 1))
        response = genHeader(204)
      end
    elseif path == 'api/node' then
      local s = node.chipid()
      s = s .. ',' .. tostring(node.uptime())
      s = s .. ',' .. tostring(node.heap())
      response = genHeader(200, 'text/plain', #s)
      table.insert(response, s)
    elseif path and file.exists(path) then
      local ext = string.match(path, '%.([^.]+)$')
      response = genHeader(200, mimeTypes[ext], files[path])
      local fd = file.open(path, 'r')
      repeat
        local s = fd:read()
        if s then
          table.insert(response, s)
        end
      until not s
      fd:close()
    else
      response = genHeader(404)
    end

    local function send(localSocket)
      if #response > 0 then
        localSocket:send(table.remove(response, 1))
      else
        localSocket:close()
        response = nil
      end
    end

    sck:on("sent", send)
    send(sck)
    -- https://nodemcu.readthedocs.io/en/dev-esp32/modules/net/#example_6
  end)
end)
