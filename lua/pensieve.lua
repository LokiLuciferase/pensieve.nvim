local Utils = require("pensieve/utils")
local Repo = require("pensieve/repo")
local pensieve = {}

PensieveRepo = nil

local function with_defaults(options)
    return {
        default_encryption = options.default_encryption or "gocryptfs",
        encryption_timeout = options.encryption_timeout or "10m",
        spell_langs = options.spell_langs or {"en_us"},
        open_in_new_tab = options.open_in_new_tab or true,
    }
end

-- This function is supposed to be called explicitly by users to configure this
-- plugin
function pensieve.setup(options)
    -- avoid setting global values outside of this function. Global state
    -- mutations are hard to debug and test, so having them in a single
    -- function/module makes it easier to reason about all possible changes
    pensieve.options = with_defaults(options)

    -- do here any startup your plugin needs, like creating commands and
    -- mappings that depend on values passed in options
    vim.api.nvim_create_user_command(
        "PensieveInit",
        function(opts)
            pensieve.init_repo(opts.fargs[1])
        end,
        { nargs = "?", complete = "dir" }
    )
    vim.api.nvim_create_user_command(
        "Pensieve",
        function(opts)
            pensieve.open_repo(opts.fargs[1])
            pensieve.edit_entry(opts.fargs[2])
        end,
        { nargs = "+", complete = "dir" }
    )
    vim.api.nvim_create_user_command(
        "PensieveOpen",
        function(opts)
            pensieve.open_repo(opts.fargs[1])
        end,
        { nargs = "?", complete = "dir" }
    )
    vim.api.nvim_create_user_command(
        "PensieveClose",
        function(opts)
            pensieve.close_repo()
        end,
        { nargs = 0 }
    )
    vim.api.nvim_create_user_command(
        "PensieveEdit",
        function(opts)
            pensieve.edit_entry(opts.fargs[1])
        end,
        { nargs = "?" }
    )
    vim.api.nvim_create_user_command(
        "PensieveAttach",
        function(opts)
            pensieve.attach(opts.fargs[1], opts.fargs[2])
        end,
        { nargs = "+", complete = "file" }
    )
end


function pensieve.is_configured()
    return pensieve.options ~= nil
end


function pensieve.open_repo(dirname)
    if not pensieve.is_configured() then
        return
    end
    if (dirname == nil or dirname == '') then
        vim.api.nvim_err_writeln("No directory was passed.")
        return
    end
    if PensieveRepo ~= nil then
        PensieveRepo:close()
        PensieveRepo = nil
    end
    local repo = Repo:new(dirname, pensieve.options)
    repo:open()
    if not repo:is_open() then
        vim.api.nvim_err_writeln("Could not open repo.")
        return
    end
    PensieveRepo = repo
end


function pensieve.close_repo()
    if not pensieve.is_configured() then
        return
    end
    if PensieveRepo == nil then
        return
    end
    PensieveRepo:close()
    PensieveRepo = nil
end


function pensieve.edit_entry(datestring)
    if not pensieve.is_configured() then
        return
    end
    if PensieveRepo == nil then
        vim.api.nvim_err_writeln("No repo is open.")
        return
    end
    PensieveRepo:open_entry(datestring)
end


function pensieve.attach(glob, datestring)
    if not pensieve.is_configured() then
        return
    end
    if PensieveRepo == nil then
        vim.api.nvim_err_writeln("No repo is open.")
        return
    end
    PensieveRepo:attach(glob, datestring)
end


function pensieve.init_repo(dirname)
    if not pensieve.is_configured() then
        return
    end
    if dirname == nil then
        vim.api.nvim_err_writeln("No directory was passed.")
        return
    end
    local repo = Repo:new(dirname, pensieve.options)
    repo:init_on_disk()
    PensieveRepo = repo
    vim.api.nvim_out_write("Initialized repo in " .. dirname)
end


pensieve.options = nil
return pensieve
