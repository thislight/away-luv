-- Copyright (C) 2020 thisLight
-- 
-- This file is part of away-luv.
-- 
-- away-luv is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
-- 
-- away-luv is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
-- 
-- You should have received a copy of the GNU General Public License
-- along with away-luv.  If not, see <http://www.gnu.org/licenses/>.
local away = require "away"
local luvserv = require "away.luv.service"
local TCPServer = require "away.luv.tcp_server"
local TCPClient = require "away.luv.tcp_client"
local Timer = require "away.luv.timer"
local scheduler = away.scheduler

luvserv:set_uv_loop_mode('nowait')

scheduler:install(luvserv)

scheduler:run_task(function()
    local server = TCPServer:create()
    server:bind('127.0.0.1', 8964)
    server.backlog = 16
    local counter = 0
    for sock in server:accept_each() do
        counter = counter + 1
        sock:write(tostring(counter))
        Timer:once_exposed(200) -- make sure data sent
        sock:close()
        if counter >= 3 then break end
    end
    server:close()
end)

scheduler:run_task(function()
    local client1 = TCPClient:connect('127.0.0.1', 8964)
    local client2 = TCPClient:connect('127.0.0.1', 8964)
    local client3 = TCPClient:connect('127.0.0.1', 8964)
    for _, sock in ipairs {client1, client2, client3} do
        local name, err = sock:read()
        if err then
            print(err)
        end
        print(string.format("Hello %s!", name))
        sock:close()
    end
    scheduler:stop()
end)

scheduler:run()
