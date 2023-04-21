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
        spell_langs = options.spell_langs,
        open_in_new_tab = options.open_in_new_tab,
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

function Repo:buf_setup_spell()
    self:fail_if_not_open()
    local spath = self.repopath .. "/meta/spell/spell.add"
    vim.opt_local.spell = true
    vim.opt_local.spelllang = table.concat(self.spell_langs, ",")
    vim.opt_local.spellfile = spath
    vim.cmd("silent! mkspell! " .. spath .. ".spl" .. " " .. spath)
end

function Repo:buf_setup_md()
    self:fail_if_not_open()
    vim.opt_local.filetype = "markdown"
    vim.opt_local.wrap = true
    vim.opt_local.textwidth = 0
    vim.opt_local.linebreak = true
    vim.opt_local.showbreak = ''
    vim.opt_local.spellcapcheck = 'none'
    vim.opt_local.diffopt = vim.opt.diffopt + ',iwhite,iblank,followrap'
    vim.api.nvim_buf_set_keymap(0, 'n', 'j', 'gj', {noremap = true, silent = true})
    vim.api.nvim_buf_set_keymap(0, 'n', 'k', 'gk', {noremap = true, silent = true})
    vim.api.nvim_buf_set_keymap(0, 'n', '0', 'g0', {noremap = true, silent = true})
    vim.api.nvim_buf_set_keymap(0, 'n', '$', 'g$', {noremap = true, silent = true})
    vim.api.nvim_buf_set_keymap(0, 'v', 'j', 'gj', {noremap = true, silent = true})
    vim.api.nvim_buf_set_keymap(0, 'v', 'k', 'gk', {noremap = true, silent = true})
    vim.api.nvim_buf_set_keymap(0, 'v', '0', 'g0', {noremap = true, silent = true})
    vim.api.nvim_buf_set_keymap(0, 'v', '$', 'g$', {noremap = true, silent = true})
end

function Repo:open_entry(date_abbrev)
    self:fail_if_not_open()
    local datestr = Utils.parse_date_abbrev(date_abbrev)
    local datesplit = Utils.splitstring(datestr, "-")
    if #datesplit ~= 3 then
        error("Invalid date string: " .. datestr)
    end

    local fpath = self.repopath .. "/entries/" .. datesplit[1] .. "/" .. datesplit[2] .. "/" .. datesplit[3] .. "/entry.md"
    vim.fn.mkdir(vim.fn.fnamemodify(fpath, ":h"), "p")
    if self.open_in_new_tab and (vim.fn.bufname("%") ~= "") then
        vim.cmd("tabe " .. fpath)
    else
        vim.cmd("e " .. fpath)
    end
    if not Utils.file_exists(fpath) then
        vim.api.nvim_buf_set_lines(0, 0, -1, false, Skeleton.get_daily(datestr))
        Skeleton.assume_default_position()
    end
    self:buf_setup_md()
    self:buf_setup_spell()
end

return Repo
