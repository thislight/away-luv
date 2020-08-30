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
local luv = require "luv"
local luvserv = require "away.luv.service"
local utils = require "away.luv.utils"
local co = coroutine

local tcp_client = {}

function tcp_client:clone_to(new_t) return utils.table_deep_copy(self, new_t) end

function tcp_client:warp(stream_t)
    return self:clone_to{
        _uvraw = stream_t,
        dataqueue = {},
        reading_flag = false,
        eof = false
    }
end

function tcp_client:create(flags) return self:warp(luv.new_tcp(flags)) end

function tcp_client:connect(host, port, flags)
    local object = self:create(flags)
    luv.tcp_connect(object._uvraw, host, port, luvserv:bind_callback())
    local sig = away.wait_signal_like(nil, {kind = 'callback'})
    local err = table.unpack(sig.result)
    if err then
        object:close()
        return nil, err
    else
        return object
    end
end

function tcp_client:set_nodelay(enable)
    return utils.auto_luv_fail_trans(luv.tcp_nodelay(self._uvraw, enable))
end

function tcp_client:set_keepalive(enable, delay)
    return utils.auto_luv_fail_trans(luv.tcp_keepalive(self._uvraw, enable,
                                                       delay))
end

function tcp_client:close()
    luv.close(self._uvraw, luvserv:bind_callback())
    co.yield()
end

function tcp_client:read()
    if not self.reading_flag then
        self.reading_flag = true
        luv.read_start(self._uvraw, function(err, data)
            if err then
                self.err = err
            elseif data then
                table.insert(self.dataqueue, data)
            else
                self.eof = true
                luv.read_stop(self._uvraw)
            end
        end)
    end
    while true do
        if self.err then
            return nil, self.err
        elseif #self.dataqueue > 0 then
            return table.remove(self.dataqueue, 1)
        else
            luvserv:bind_callback()()
            co.yield()
        end
    end
end


function tcp_client:write(data, blocking)
    local callback = nil
    if blocking then
        callback = luvserv:bind_callback()
    end
    return utils.auto_luv_fail_trans(luv.write(self._uvraw, data, callback))
end

return tcp_client
