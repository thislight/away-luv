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

local luv = require 'luv'

local co = coroutine

local luv_service = {}

function luv_service:install(scheduler)
    local uvthread = co.create(function()
        while true do
            luv.run('nowait')
            co.yield()
        end
    end)
    self.scheduler = scheduler
    scheduler:set_auto_signal(function() return {target_thread = uvthread} end)
end

function luv_service:bind_callback()
    local current_thread = self.scheduler.current_thread
    local scheduler = self.scheduler
    return function(...)
        scheduler:push_signal{
            target_thread = current_thread,
            kind = 'callback',
            result = table.pack(...)
        }
    end
end

return luv_service
