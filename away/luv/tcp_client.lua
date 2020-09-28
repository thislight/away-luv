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
local Dataqueue = require "away.dataqueue"
local co = coroutine

local tcp_client = {}

function tcp_client:clone_to(new_t) return utils.table_deep_copy(self, new_t) end

function tcp_client:warp(stream_t)
    return self:clone_to{
        _uvraw = stream_t,
        dataqueue = {},
        reading_flag = false,
        eof = false,
        maxbuffer = 50,
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

function tcp_client:start_read(data_queue)
    luv.read_start(self._uvraw, function(err, data)
        if err then
            data_queue:set_error(err)
        elseif data then
            data_queue:add(data)
        else
            data_queue:set_error('disconnected')
        end
    end)
    return data_queue
end

function tcp_client:stop_read()
    luv.read_stop(self._uvraw)
end

function tcp_client:read()
    if not self._internal_dataqueue then
        self._internal_dataqueue = Dataqueue:with_limit(
            self.maxbuffer,
            function(dq)
                self:start_read(dq)
            end,
            function(dq)
                self:stop_read()
            end
        )
    end
    return self._internal_dataqueue:next()
end


function tcp_client:write(data, blocking)
    if blocking then
        local callback = luvserv:bind_callback()
        luv.write(self._uvraw, data, callback)
        local sig = away.wait_signal_like(nil, { kind = 'callback' })
        if #sig.result > 0 then
            return false, sig.result[0]
        else
            return true, nil
        end
    else
        return utils.auto_luv_fail_trans(luv.write(self._uvraw, data))
    end
end

return tcp_client
