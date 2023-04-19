require "pensieve.repo"

local repo = Repo:new("~/testing-raw", {encryption="plaintext"})
repo:open()
repo:initOnDisk()
rv = repo:isOpen()
print(rv)
dp = repo:getDailyPath()
print(dp)
repo:close()
rv = repo:isOpen()
print(rv)
repo:close()
