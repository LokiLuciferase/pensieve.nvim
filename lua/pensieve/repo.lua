local Utils = require("pensieve.utils")
local GocryptFS = require("pensieve.crypt")

Repo = {}

local function get_encryption(dirpath)
    local cmd = 'test -z "$(ls -A ' .. dirpath .. ' 2> /dev/null)"'
    if ((not vim.fn.isdirectory(dirpath)) or (os.execute(cmd) / 256) == 0) then
        rv = nil
    elseif Utils.file_exists(dirpath .. "/meta/repo.json") then
        rv = "plaintext"
    elseif Utils.file_exists(dirpath .. "/cipher/gocryptfs.conf") then
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
    if get_encryption(self.dirpath) then
        error("Repo already exists at <" .. vim.fn.expand(self.dirpath) .. ">.")
    end
    if self.encryption == 'gocryptfs' then
        vim.fn.mkdir(self.dirpath .. '/cipher', 'p')
        vim.fn.mkdir(self.dirpath .. '/plain', 'p')
        local pensieve_pw_v1 = vim.fn.inputsecret("Password: ")
        local pensieve_pw_v2 = vim.fn.inputsecret("Repeat password: ")
        print("")
        GocryptFS.init(self.dirpath, pensieve_pw_v1, pensieve_pw_v2)
        GocryptFS.open(self.dirpath, pensieve_pw_v1, self.encryption_timeout)

    end
    vim.fn.mkdir(self.repopath .. "/entries", "p")
    vim.fn.mkdir(self.repopath .. "/meta", "p")
    os.execute("touch " .. self.repopath .. "/meta/repo.json")
    if not self:is_open() then
        error("Could not initialize repo.")
    end
    if self.encryption == 'gocryptfs' then
        GocryptFS.close(self.dirpath)
    end
    print("\r\n")
    print("Repo initialized at <" .. vim.fn.expand(self.dirpath) .. ">, encryption = " .. self.encryption .. ".")
end

function Repo:is_open()
    return Utils.file_exists(self.repopath .. "/meta/repo.json")
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

return Repo
