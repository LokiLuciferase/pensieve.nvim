require "pensieve.crypt"

Repo = {}

function Repo:new(dirpath, options)
    local options = options or {}
    local dirpath = vim.fn.expand(dirpath)
    newobj = {
        dirpath = dirpath,
        encryption = options.encryption,
        encryption_timeout = options.encryption_timeout
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
    vim.fn.mkdir(self.repopath .. "/entries", "p")
    vim.fn.mkdir(self.repopath .. "/meta", "p")
    os.execute("touch " .. self.repopath .. "/meta/repo.json")
end

function Repo:isOpen()
    retval = vim.fn.filereadable(self.repopath .. "/meta/repo.json")
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

        local pensieve_pw = nil
        vim.ui.input(
            {prompt = "Password: "},
            function(input) pensieve_pw = input end
        )
        GocryptFS.Open(self.dirpath, pensieve_pw, self.encryption_timeout)
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

function Repo:getDailyPath()
    self:failIfNotOpen()
    local dt = os.date("%Y/%m/%d")
    local ddir = self.repopath .. "/entries/" .. dt
    local df = ddir .. "/entry.md"
    local attd = ddir .. "/attachments"
    vim.fn.mkdir(attd, "p")
    return df
end

return Repo
