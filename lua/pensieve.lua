local Utils = require("pensieve/utils")
local Repo = require("pensieve/repo")
local pensieve = {}

local function with_defaults(options)
    return {
        default_encryption = options.default_encryption or "gocryptfs",
        encryption_timeout = options.encryption_timeout or "10m",
        spell_langs = options.spell_langs or {"en_us"},
        open_in_new_tab = options.open_in_new_tab or false,
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
        "Pensieve",
        function(opts)
            pensieve.write_daily(opts.fargs[1], opts.fargs[2])
        end,
        { nargs = "+", complete = "dir" }
    )
    vim.api.nvim_create_user_command(
        "PensieveInit",
        function(opts)
            pensieve.init_repo(opts.fargs[1])
        end,
        { nargs = "?", complete = "dir" }
    )
end

function pensieve.is_configured()
    return pensieve.options ~= nil
end

function pensieve.write_daily(dirname, datestring)
    if not pensieve.is_configured() then
        return
    end
    if (dirname == nil or dirname == '') then
        vim.api.nvim_err_writeln("Cannot open repo: no directory passed.")
        return
    end
    local repo = Repo:new(dirname, pensieve.options)
    repo:open()
    if not repo:is_open() then
        vim.api.nvim_err_writeln("Could not open repo.")
        return
    end
    repo:open_entry(datestring)
end

function pensieve.init_repo(dirname)
    if not pensieve.is_configured() then
        return
    end
    if dirname == nil then
        vim.api.nvim_err_writeln("The passed directory is not readable.")
        return
    end
    local repo = Repo:new(dirname, pensieve.options)
    repo:init_on_disk()
    vim.api.nvim_out_write("Initialized repo in " .. dirname)
end

pensieve.options = nil
return pensieve
