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
local luvservice = require "away.luv.service"
local scheduler = away.scheduler
local timer = require "away.luv.timer"

scheduler:install(luvservice)

scheduler:run_task(function ()
    print("task 1", "once 1000")
    timer:once(1000, function() print("task 1 done") end)
end)

scheduler:run_task(function ()
    print("task 2", "repeat 3 times")
    local count = 0
    timer:repeated(500, function(t)
        count = count + 1
        print("task 2", "repeat ", count)
        if count >= 3 then
            t:close()
        end
    end)
end)

scheduler:run_task(function()
    print("task 3", "exposed once 10000")
    timer:once_exposed(10000)
    print("task 3 done")
    scheduler:stop()
end)

scheduler:run_task(function()
    print("task 4", "exposed repeat 3 times")
    local count = 0
    for t in timer:repeated_exposed(1000) do
        count = count + 1
        print("task 4", "repeat ", count)
        if count >= 3 then
            t:close()
        end
    end
end)

scheduler:run()
