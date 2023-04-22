local Utils = require("pensieve/utils")
local CapCheck = require("pensieve/cap_check")
local GocryptFS = require("pensieve/crypt")
local Skeleton = require("pensieve/skeleton")

Repo = {}

local function get_encryption(dirpath)
    local cmd = 'test -z "$(ls -A ' .. dirpath .. ' 2> /dev/null)"'
    local retval = os.execute(cmd)
    if type(retval) == "number" then
        retval = retval / 256
    else
        if retval == true then
            retval = 0
        else
            retval = 1
        end
    end
    if ((not vim.fn.isdirectory(dirpath)) or retval == 0) then
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

function Repo:setup_vimwiki()
    self:fail_if_not_open()
    vim.g.vimwiki_list = {{
        path = self.repopath,
        path_html = self.repopath .. "/html",
        syntax = 'markdown',
        ext = '.md',
        auto_header = 1,
        auto_tags = 1,
        auto_toc = 1,
        auto_diary_index = 1,
        auto_generate_tags = 1,
        auto_generate_links = 1,
        diary_header = 'Diary Index',
        diary_rel_path = 'entries/',
        diary_index = 'index',
        use_mouse = 1,
        use_calendar = 1,
    }}
    vim.cmd('call vimwiki#vars#init()')
    vim.g.vimwiki_global_ext = 0
end

function Repo:setup_spell()
    self:fail_if_not_open()
    local spath = self.repopath .. "/meta/spell/spell.add"
    vim.opt.spell = true
    vim.opt.spelllang = table.concat(self.spell_langs, ",")
    vim.opt.spellfile = spath
    vim.cmd("silent! mkspell! " .. spath .. ".spl" .. " " .. spath)
end

function Repo:setup_md()
    self:fail_if_not_open()
    vim.o.autochdir = true
    vim.o.filetype = "markdown"
    vim.o.wrap = true
    vim.o.textwidth = 0
    vim.o.linebreak = true
    vim.o.showbreak = ''
    vim.o.spellcapcheck = 'none'
    vim.api.nvim_buf_set_keymap(0, 'n', 'j', 'gj', {noremap = true, silent = true})
    vim.api.nvim_buf_set_keymap(0, 'n', 'k', 'gk', {noremap = true, silent = true})
    vim.api.nvim_buf_set_keymap(0, 'n', '0', 'g0', {noremap = true, silent = true})
    vim.api.nvim_buf_set_keymap(0, 'n', '$', 'g$', {noremap = true, silent = true})
    vim.api.nvim_buf_set_keymap(0, 'v', 'j', 'gj', {noremap = true, silent = true})
    vim.api.nvim_buf_set_keymap(0, 'v', 'k', 'gk', {noremap = true, silent = true})
    vim.api.nvim_buf_set_keymap(0, 'v', '0', 'g0', {noremap = true, silent = true})
    vim.api.nvim_buf_set_keymap(0, 'v', '$', 'g$', {noremap = true, silent = true})
end

function Repo:register_close_hook()
    -- register augroup/autocmd to close repo on nvim exit
    local cwd_pre = vim.fn.getcwd()
    local group = vim.api.nvim_create_augroup("pensieve", {clear = false})
    vim.api.nvim_create_autocmd('VimLeavePre', {group = group, callback = function() vim.fn.chdir(cwd_pre) self:close() end})
end

function Repo:init_on_disk()
    if get_encryption(self.dirpath) then
        error("Repo already exists at <" .. vim.fn.expand(self.dirpath) .. ">.")
    end
    if self.encryption == 'gocryptfs' then
        vim.fn.mkdir(self.dirpath .. '/cipher', 'p')
        vim.fn.mkdir(self.dirpath .. '/plain', 'p')
        local pensieve_pw_v1 = vim.fn.inputsecret("Initalizing repo, password: ")
        local pensieve_pw_v2 = vim.fn.inputsecret("Initializing repo, repeat password: ")
        print("")
        GocryptFS.init(self.dirpath, pensieve_pw_v1, pensieve_pw_v2)
        GocryptFS.open(self.dirpath, pensieve_pw_v1, self.encryption_timeout)
        self:register_close_hook()
    end
    vim.fn.mkdir(self.repopath .. "/entries", "p")
    vim.fn.mkdir(self.repopath .. "/meta", "p")
    vim.fn.mkdir(self.repopath .. "/meta/spell", "p")
    os.execute("touch " .. self.repopath .. "/meta/repo.json")
    os.execute("touch " .. self.repopath .. "/meta/spell/spell.add")
    if not self:is_open() then
        error("Could not initialize repo.")
    end
    print("\r\n")
    print("Repo initialized at <" .. vim.fn.expand(self.dirpath) .. ">, encryption = " .. self.encryption .. ".")
    self:close()
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
        local pensieve_pw = vim.fn.inputsecret("Opening repo, password: ")
        GocryptFS.open(self.dirpath, pensieve_pw, self.encryption_timeout)
        if not self:is_open() then
            vim.api.nvim_err_writeln("Could not open repo.")
            return
        end
    end

    self:register_close_hook()
    self:setup_spell()
    self:setup_md()
    if CapCheck.vimwiki then
        self:setup_vimwiki()
        vim.cmd("VimwikiDiaryIndex")
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

function Repo:open_entry(date_abbrev)
    self:fail_if_not_open()
    local datestr = Utils.parse_date_abbrev(date_abbrev)
    local datesplit = Utils.splitstring(datestr, "-")
    if #datesplit ~= 3 then
        error("Invalid date string: " .. datestr)
    end

    local fpath = self.repopath .. "/entries/" .. datestr .. ".md"
    if self.open_in_new_tab and (vim.fn.bufname("%") ~= "") then
        vim.cmd("tabe " .. fpath)
    else
        vim.cmd("e " .. fpath)
    end
    if not Utils.file_exists(fpath) then
        vim.api.nvim_buf_set_lines(0, 0, -1, false, Skeleton.get_daily(datestr))
        Skeleton.assume_default_position()
    end
end

function Repo:attach(glob, date_abbrev)
    self:fail_if_not_open()
    local datestr = Utils.parse_date_abbrev(date_abbrev)
    local datesplit = Utils.splitstring(datestr, "-")
    if #datesplit ~= 3 then
        error("Invalid date string: " .. datestr)
    end
    local attd = self.repopath .. "/entries/" .. datestr .. "/"
    vim.fn.mkdir(attd, "p")
    local files = vim.fn.glob(glob, true, true)
    for key,value in pairs(files) do
        local fname = vim.fn.fnamemodify(value, ":t")
        local fpath = attd .. fname
        if not Utils.file_exists(fpath) then
            os.execute("cp -Lr " .. value .. " " .. fpath)
        end
    end
    print("Attached " .. #files .. " files/dirs to entry " .. datestr .. " in repo <" .. self.repopath .. ">.")
end

return Repo
