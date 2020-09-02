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
local luv = require "luv"
local luvserv = require "away.luv.service"
local utils = require "away.luv.utils"
local TCPClient = require "away.luv.tcp_client"
local co = coroutine

local tcp_server = {}

function tcp_server:clone_to(new_t) return utils.table_deep_copy(self, new_t) end

function tcp_server:create(flags)
    return self:warp(luv.new_tcp(flags))
end

function tcp_server:warp(new_tcp)
    return self:clone_to {
        _uvraw = new_tcp
    }
end

function tcp_server:shutdown(callback)
    if callback then
        luv.shutdown(self._uvraw, function() callback(self) end)
    else
        luv.shutdown(self._uvraw, luvserv:bind_callback())
        co.yield()
    end
end

function tcp_server:accept(backlog)
    local queue = {}
    local need_callback = false
    local local_callback = luvserv:bind_callback()
    luv.listen(self._uvraw, backlog, function(err)
        local raw_tcp = luv.new_tcp()
        luv.accept(self._uvraw, raw_tcp)
        table.insert(queue, raw_tcp)
        if need_callback then
            print('callback')
            need_callback = false
            local_callback()
        end
    end)
    return function()
        while true do
            if #queue > 0 then
                local sock = table.remove(queue, 1)
                return TCPClient:warp(sock)
            elseif self:is_closing() then
                return nil
            else
                need_callback = true
                co.yield()
                need_callback = false
            end
        end
    end
end

function tcp_server:bind(host, port, flags)
    return utils.auto_luv_fail_trans(luv.tcp_bind(self._uvraw, host, port, flags))
end

function tcp_server:close()
    luv.close(self._uvraw, luvserv:bind_callback())
    co.yield()
end

function tcp_server:set_simultaneous_accepts(enable)
    return utils.auto_luv_fail_trans(luv.tcp_simultaneous_accepts(self._uvraw, enable))
end

function tcp_server:is_closing() return luv.is_closing(self._uvraw) end

return tcp_server
