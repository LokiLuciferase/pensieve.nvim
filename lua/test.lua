require "pensieve.repo"

local repo = Repo:new("~/testing")
repo:open()
repo:initOnDisk()
rv = repo:isOpen()
print(rv)
print(repo:getDaily())
repo:close()
rv = repo:isOpen()
print(rv)
repo:close()
