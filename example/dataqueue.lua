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
local away = require 'away'
local LuvService = require 'away.luv.service'
local Dataqueue = require('away.luv.dataqueue').dataqueue
local Scheduler = away.scheduler

Scheduler:install(LuvService)

local global_queue = Dataqueue:create()

local function topstring(t)
    if type(t) == 'table' then
        local buffer =  {}
        for k,v in pairs(t) do
            table.insert(buffer, string.format("%s=%s", topstring(k), topstring(v)))
        end
        return '{'..table.concat(buffer, ',')..'}'
    elseif type(t) == 'string' then
        return '"'..t..'"'
    else
        return tostring(t)
    end
end

Scheduler:add_watcher('push_signal', function(_, signal) if not signal.is_auto_signal then print('push_signal', topstring(signal)) end end)

Scheduler:add_watcher('run_thread', function(_, thread, signal) if not signal.is_auto_signal then print('run_thread', thread,'signal', topstring(signal)) end end)

Scheduler:run_task(function()
    while not global_queue:is_marked_end() do
        print('call next()')
        local val, err = global_queue:next()
        if val then
            print(string.format("Hello %s!",val))
        elseif err == 'ended' then
            Scheduler:stop()
        end
    end
end)

Scheduler:run_task(function()
    global_queue:add('J. Cooper')
    LuvService:schedule_wake_back()
    print('wakeback!')
    global_queue:add('BT')
    LuvService:schedule_wake_back()
    print('wakeback!')
    global_queue:add('Anderson')
    LuvService:schedule_wake_back()
    print('wakeback!')
    global_queue:mark_end()
end)

Scheduler:run()
