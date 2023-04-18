require "pensieve.crypt"

Repo = {}

function Repo:new(dirpath, options)
    local options = options or {}
    newobj = {
        dirpath = dirpath,
        encryption = options.encryption or "gocryptfs" 
    }
    if newobj.encryption == "gocryptfs" then
        newobj.repopath = dirpath .. "/plain"
    else
        newobj.repopath = dirpath
    end

    self.__index = self
    ret = setmetatable(newobj, self)
    return ret
end

function Repo:initOnDisk()
    os.execute("mkdir -p " .. self.repopath .. "/entries")
    os.execute("mkdir -p " .. self.repopath .. "/meta")
    os.execute("touch " .. self.repopath .. "/meta/repo.json")
end

function Repo:isOpen()
    local cmd = 'test ! -f ' .. self.repopath .. '/meta/repo.json'
    local retval = os.execute(cmd) / 256
    if retval == 1 then
        return true
    else
        return false
    end
end

function Repo:failIfNotOpen()
    if not self:isOpen() then
        error("Repo is not open, cannot perform operation.")
    end
end

function Repo:open()
    if self:isOpen() then
        return
    end
    if self.encryption == "gocryptfs" then
        -- TODO: should prompt for pw here
        pw = "test"
        GocryptFS.Open(self.dirpath, pw)
    end
end

function Repo:close()
    if not self:isOpen() then
        return
    end
    if self.encryption == "gocryptfs" then
        GocryptFS.Close(self.dirpath)
    end
end

function Repo:getDaily()
    self:failIfNotOpen()
    local dt = os.date("%Y-%m-%d")
    local ddir = self.repopath .. "/entries/" .. dt
    local df = ddir .. "/entry.md"
    local attd = ddir .. "/attachments"
    return df  -- TODO: actually create templatedd filde _ bvim api
end

return Repo
