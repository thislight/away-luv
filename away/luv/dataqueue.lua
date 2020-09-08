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
local utils = require "away.luv.utils"

local co = coroutine

local dataqueue_service = {installed_flag = false, waited_dataqueue = {}}

function dataqueue_service:install(scheduler)
    if not self.installed_flag then
        local keepalive_thread = coroutine.create(
                                     function(self)
                while true do
                    co.yield()
                    local process_queue = {}
                    table.move(self.waited_dataqueue, 1, #self.waited_dataqueue,
                               1, process_queue)
                    for i,dataqueue in ipairs(process_queue) do
                        if dataqueue:need_wake_back() then
                            self:perform_wakeback(scheduler, dataqueue)
                            dataqueue.waiting_threads = {}
                            table.remove(self.waited_dataqueue, i)
                        end
                    end
                end
            end)
        co.resume(keepalive_thread, self)
        scheduler:set_auto_signal(function()
            return {target_thread = keepalive_thread}
        end)
        self.installed_flag = true
    end
end

function dataqueue_service:add_waited_queue(dq)
    table.insert(self.waited_dataqueue, dq)
end

function dataqueue_service:perform_wakeback(scheduler, dq)
    for _,thread in ipairs(dq.waiting_threads) do
        if co.status(thread) ~= 'dead' then
            scheduler:push_signal{
                target_thread = thread,
                kind = 'dataqueue_wake_back',
                queue = dq
            }
        end
    end
end

local dataqueue = {}

function dataqueue:clone_to(new_t) return utils.table_deep_copy(self, new_t) end

function dataqueue:create()
    return self:clone_to{data = {}, waiting_threads = {}}
end

function dataqueue:with_limit(limit, novalue_callback, limitreach_callback)
    local obj = self:create()
    obj.length_limit = limit
    obj.novalue_callback = novalue_callback
    obj.limitreach_callback = limitreach_callback
    return obj
end

function dataqueue:add(value)
    table.insert(self.data, value)
    if self.length_limit and (#self.data >= self.length_limit) then
        if self.limitreach_callback then self.limitreach_callback() end
    end
end

function dataqueue:next()
    local value, err = self:try_next()
    if value or err then
        return value, err
    else
        if self.novalue_callback then
            self:novalue_callback()
        end
        dataqueue_service:add_waited_queue(self)
        table.insert(self.waiting_threads, away.get_current_thread())
        away.wait_signal_like(nil, {kind = 'dataqueue_wake_back', queue = self})
        return self:try_next()
    end
end

function dataqueue:listen(callback)
    local d = {}
    local thread = co.create(function(dq, descriptor, callback)
        co.yield()
        while true do
            if descriptor.stop then break end
            local value, err = dq:next()
            callback(value, err, descriptor)
        end
    end)
    d.dataqueue = self
    co.resume(thread, self, d, callback)
    away.schedule_thread(thread)
end

function dataqueue:try_next()
    if self:has_data() then
        return table.remove(self.data, 1), nil
    elseif self:has_error() then
        return nil, self.error
    else
        return nil, nil
    end
end

function dataqueue:has_data() return #self.data > 0 end

function dataqueue:set_error(err) self.error = err end

function dataqueue:has_error() return self.error ~= nil end

function dataqueue:need_wake_back() return self:has_data() or self:has_error() end

function dataqueue:is_marked_end() return self.error == 'ended' end

function dataqueue:mark_end() self:set_error('ended') end

return {
    service = dataqueue_service,
    dataqueue = dataqueue,
}
