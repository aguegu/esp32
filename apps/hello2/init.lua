local led = 2
gpio.config({ gpio = led, dir = gpio.IN_OUT })

local statusText = {}

statusText[200] = "OK"
statusText[204] = "No Content"
statusText[404] = "Not Found"

local mimeTypes = {
  html='text/html',
  js='text/javascript',
  ico='image/vnd.microsoft.icon',
  css='text/css'
}

local hostname = 'ESP32#2'

wifi.mode(wifi.STATION)
wifi.start()
wifi.sta.sethostname(hostname)

srv = net.createServer(net.TCP)

local function genHeader(status, type, length, isGz)
  local header = {
    "HTTP/1.1 " .. tostring(status) .. " " .. statusText[status] .. "\r\nConnection: close\r\nX-Powered-By: nodemcu\r\n",
  }
  if status == 200 then
    table.insert(header, "Content-Length: " .. length .. "\r\nContent-Type: " .. type .. "\r\n")
    if isGz then table.insert(header, "Content-Encoding: gzip\r\n") end
  elseif status == 404 then
    table.insert(header, "Content-Length: 0\r\n")
  end

  table.insert(header, "\r\n")
  return header
end

local files = file.list()

srv:listen(80, function(conn)
  conn:on("receive", function (sck, req)
    print(sck, req)

    local _, _, method, path = string.find(req, "^(%w+) /(.*) HTTP/1\.1")
    local response = {}

    path = path == '' and 'index.html' or path
    local realpath = path .. '.gz'

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
      local s = table.concat({ hostname, node.chipid(), tostring(node.uptime()), tostring(node.heap()) }, ',')
      response = genHeader(200, 'text/plain', #s)
      table.insert(response, s)
    elseif path and file.exists(realpath) then
      local ext = string.match(path, '%.([^.]+)$')
      response = genHeader(200, mimeTypes[ext], files[realpath], true)
      local fd = file.open(realpath, 'r')
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
      -- print('in send: ', localSocket, #response)
      if localSocket then
        if #response > 0 then
          localSocket:send(table.remove(response, 1))
        else
          localSocket:close()
          response = nil
        end
      else
        collectgarbage()
      end
    end

    sck:on("sent", send)

    sck:on("disconnection", function (sck, err)
      print('in disconnection', sck, err)
    end)

    send(sck)
    -- https://nodemcu.readthedocs.io/en/dev-esp32/modules/net/#example_6
  end)
end)
