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
local Debugger = require 'away.debugger'
local Dataqueue = require('away.luv.dataqueue').dataqueue
local Scheduler = away.scheduler

Scheduler:install(LuvService)

local global_queue = Dataqueue:create()

Scheduler:add_watcher('push_signal', function(_, signal) if not signal.is_auto_signal then print('push_signal', Debugger.topstring(Debugger:pretty_signal(signal))) end end)

Scheduler:add_watcher('run_thread', function(_, thread, signal) if not signal.is_auto_signal then print('run_thread', Debugger:remap_thread(thread),'signal', Debugger.topstring(Debugger:pretty_signal(signal))) end end)

Scheduler:run_task(function()
    while true do
        print('call next()')
        local val, err = global_queue:next()
        if val then
            print(string.format("Hello %s!",val))
        elseif err then
            print(err)
            break
        end
    end
    Scheduler:stop()
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
