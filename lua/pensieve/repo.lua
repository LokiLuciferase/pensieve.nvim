require "pensieve.crypt"

Repo = {}

local function file_exists(f)
    local rv = vim.fn.filereadable(f)
    if rv == 1 then
        return true
    else
        return false
    end
end

local function get_encryption(dirpath)
    local cmd = 'test -z "$(ls -A ' .. dirpath .. ')"'
    if ((not vim.fn.isdirectory(dirpath)) or (os.execute(cmd) / 256) == 0) then
        rv = nil
    elseif file_exists(dirpath .. "/meta/repo.json") then
        rv = "plaintext"
    elseif file_exists(dirpath .. "/cipher/gocryptfs.conf") then
        rv = "gocryptfs"
    else
        error("Could not identify repo encryption.")
    end
    return rv
end

function Repo:new(dirpath, options)
    local options = options or {}
    local dirpath = vim.fn.expand(dirpath)
    newobj = {
        dirpath = dirpath,
        encryption = get_encryption(dirpath) or options.default_encryption,
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

function Repo:init_on_disk()
    vim.fn.mkdir(self.repopath .. "/entries", "p")
    vim.fn.mkdir(self.repopath .. "/meta", "p")
    os.execute("touch " .. self.repopath .. "/meta/repo.json")
end

function Repo:is_open()
    return file_exists(self.repopath .. "/meta/repo.json")
end

function Repo:fail_if_not_open()
    if not self:is_open() then
        error("Repo is not open, cannot perform operation.")
    end
end

function Repo:open()
    if self:is_open() then
        return
    end
    if self.encryption == "gocryptfs" then
        local pensieve_pw = vim.fn.inputsecret("Password: ")
        GocryptFS.open(self.dirpath, pensieve_pw, self.encryption_timeout)
    end
end

function Repo:close()
    if not self:is_open() then
        return
    end
    if self.encryption == "gocryptfs" then
        GocryptFS.close(self.dirpath)
    end
end

function Repo:get_daily_path()
    self:fail_if_not_open()
    local dt = os.date("%Y/%m/%d")
    local ddir = self.repopath .. "/entries/" .. dt
    local df = ddir .. "/entry.md"
    local attd = ddir .. "/attachments"
    vim.fn.mkdir(attd, "p")
    return df
end

function Repo:get_skeleton()
    local header = "## " .. os.date("%Y-%m-%d")
    local skel = [[
### Entry

### Emotions
### Rating
x/10
### Notes
]]
    return header .. "\n" .. skel
end

return Repo
