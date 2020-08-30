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
local utils = require "away.luv.utils"
local service = require "away.luv.service"

local timer = {}

function timer:clone_to(new_t)
    return utils.table_deep_copy(self, new_t)
end

function timer:once(timeout, callback)
    local object = self:clone_to {
        _uvraw = luv.new_timer()
    }
    local stat,err, errname = luv.timer_start(object._uvraw, timeout, 0, function() callback(object) end)
    if stat then
        return object
    else
        return nil, err, errname
    end
end

function timer:repeated(delay, callback)
    local object = self:clone_to {
        _uvraw = luv.new_timer()
    }
    local stat, err, errname = luv.timer_start(object._uvraw, delay, delay, function() callback(object) end)
    if stat then
        return object
    else
        return nil, err, errname
    end
end


function timer:once_exposed(timeout)
    self:once(timeout, service:bind_callback())
    coroutine.yield()
end

function timer:repeated_exposed(delay)
    local obj = timer:repeated(delay, service:bind_callback())
    return function()
        coroutine.yield()
        return obj
    end
end

function timer:close()
    luv.close(self._uvraw, service:bind_callback())
    if coroutine.isyieldable() then coroutine.yield() end
end

return timer
