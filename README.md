# Away for Luv

[Away](https://github.com/thislight/away) driver for [luv](https://github.com/luvit/luv).

## Install away-luv
[away-luv - LuaRocks](https://luarocks.org/modules/thislight/away-luv)

### LuaRocks
````
luarocks install away-luv
````
LuaRocks can handle all mess for you.

If you want a developing version, use the rockspec `away-luv-git-0.rockspec`.

## Use with standard luv interfaces
Install luv_service from `away.luv.service` to away scheduler, and then you can use luv interface directly.
````lua
local uv = require 'luv'
local away = require 'away'
local LuvService = require 'away.luv.service'
away.scheduler:install(LuvService)

away.scheduler:run_task(function()
    local timer = uv.new_timer()
    uv.timer_start(timer, 1000, 0, function()
        print('011404250519!')
        away.scheduler:stop()
    end)
end)

away.scheduler:run()
````

## Use with away-luv synchronous-style interfaces

> Still working on it...

See [examples](example/) and source code to explore the interfaces.

## License
GNU Gerneral Public License, version 3 or later.

    away-luv - luv service for away
    Copyright (C) 2020 thisLight <l1589002388@gmail.com>

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.

> Note on GPLv3: although you have copied code from this project, you don't need to open source if you don't convey it (see GPLv3 for definition of "convey"). This is not a legal advice.
