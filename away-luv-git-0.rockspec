package = "away-luv"
version = "git-0"
source = {
   url = "git+https://github.com/thislight/away-luv.git"
}
description = {
   homepage = "https://github.com/thislight/away-luv",
   license = "GPL-3",
   summary = "Luv adaptor for away",
   detailed = [[away-luv provides functionallity uses luv with away, and a optional sync-style interface]]
}
dependencies = {
   "luv >=1.36.0, <2",
   "away >=0.0.1, <1"
}
build = {
   type = "builtin",
   modules = {
      ["away.luv"] = "away/luv/init.lua",
      ["away.luv.service"] = "away/luv/service.lua",
      ["away.luv.timer"] = "away/luv/timer.lua",
      ["away.luv.utils"] = "away/luv/utils.lua",
   }
}
