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

local function table_deep_copy(t1, t2)
    for k, v in pairs(t1) do
        if type(v) == 'table' then
            t2[k] = table_deep_copy(v, {})
        else
            t2[k] = v
        end
    end
    return t2
end

local function auto_luv_fail_trans(stat, message, e, result)
    if stat then
        return result
    else
        return nil, message, e
    end
end

return {
    table_deep_copy = table_deep_copy,
    auto_luv_fail_trans = auto_luv_fail_trans,
}
