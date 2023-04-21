local Utils = require("pensieve.utils")
local GocryptFS = require("pensieve.crypt")
local Skeleton = require("pensieve/skeleton")

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
        encryption_timeout = options.encryption_timeout,
        spell_langs = options.spell_langs
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
    vim.fn.mkdir(self.repopath .. "/meta/spell", "p")
    os.execute("touch " .. self.repopath .. "/meta/repo.json")
    os.execute("touch " .. self.repopath .. "/meta/spell/spell.add")
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
    -- register augroup/autocmd to close repo on nvim exit
    local cwd_pre = vim.fn.getcwd()
    local group = vim.api.nvim_create_augroup("pensieve", {clear = false})
    vim.api.nvim_create_autocmd('VimLeavePre', {group = group, callback = function() vim.fn.chdir(cwd_pre) self:close() end})
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

function Repo:setup_spell()
    self:fail_if_not_open()
    local spath = self.repopath .. "/meta/spell/spell.add"
    vim.cmd("setlocal spell")
    vim.cmd("setlocal spelllang=" .. table.concat(self.spell_langs, ","))
    vim.cmd("setlocal spellfile=" .. spath)
    vim.cmd("silent! mkspell! " .. spath .. ".spl" .. " " .. spath)
end

function Repo:open_entry(fpath)
    if fpath == nil then
        local daily_path = self:get_daily_path()
        if not Utils.file_exists(daily_path) then
            vim.fn.writefile(Skeleton.get_daily(), daily_path, "s")
            vim.cmd("e " .. daily_path)
            Skeleton.assume_default_position()
        else
            vim.cmd("e " .. daily_path)
        end
    else
        vim.cmd("e " .. fpath)
    end
    self:setup_spell()
end

function Repo:open_entry_with_date(datestr)
    self:fail_if_not_open()
    if datestr == nil then
        local fpath = nil
    else
        local datesplit = Utils.splitstring(datestr, "-")
        if #datesplit ~= 3 then
            error("Invalid date string.")
        end
        local fpath = self.repopath .. datesplit[1] .. "/" .. datesplit[2] .. "/" .. datesplit[3] .. "/entry.md"
    end
    self:open_entry(fpath)
end

return Repo
