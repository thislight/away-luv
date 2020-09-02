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
local Dataqueue = require("away.luv.dataqueue").dataqueue
local TCPClient = require "away.luv.tcp_client"
local co = coroutine

local tcp_server = {
    managed_dataqueue = {},
    backlog = 128,
}

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

function tcp_server:start_accept(backlog, sock_queue)
    table.insert(self.managed_dataqueue, sock_queue)
    luv.listen(self._uvraw, backlog, function(err)
        if err then
            sock_queue:set_error(err)
        else
            local conn = luv.new_tcp()
            luv.accept(self._uvraw, conn)
            sock_queue:add(TCPClient:warp(conn))
        end
    end)
    return sock_queue
end

function tcp_server:accept()
    if not self._internal_dataqueue then
        self._internal_dataqueue = Dataqueue:create()
        self:start_accept(self.backlog, self._internal_dataqueue)
    end
    return self._internal_dataqueue:next()
end

function tcp_server:accept_each()
    return function()
        return self:accept()
    end
end

function tcp_server:bind(host, port, flags)
    return utils.auto_luv_fail_trans(luv.tcp_bind(self._uvraw, host, port, flags))
end

function tcp_server:close()
    for _, dq in ipairs(self.managed_dataqueue) do
        dq:mark_end()
    end
    luv.close(self._uvraw, luvserv:bind_callback())
    co.yield()
end

function tcp_server:set_simultaneous_accepts(enable)
    return utils.auto_luv_fail_trans(luv.tcp_simultaneous_accepts(self._uvraw, enable))
end

function tcp_server:is_closing() return luv.is_closing(self._uvraw) end

return tcp_server
