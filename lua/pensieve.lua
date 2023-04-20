local Repo = require("pensieve/repo")
local pensieve = {}

local function with_defaults(options)
    return {
        encryption = options.encryption or "gocryptfs",
        encryption_timeout = options.encryption_timeout or "10m"
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
        pensieve.ask_then_write_daily,
        {}
    )
end

function pensieve.is_configured()
    return pensieve.options ~= nil
end

function pensieve.write_daily(dirname)
    if not pensieve.is_configured() then
        return
    end
    if not dirname then
        vim.api.nvim_err_writeln("The passed directory is not readable.")
        return
    end
    local repo = Repo:new(dirname, pensieve.options)
    repo:open()
    local cwd_pre = vim.fn.getcwd()
    local dailyPath = repo:getDailyPath()
    local group = vim.api.nvim_create_augroup("pensieve", {clear = false})
    vim.api.nvim_create_autocmd('VimLeavePre', {group = group, callback = function() vim.fn.chdir(cwd_pre) repo:close() end})
    vim.cmd("e " .. dailyPath)
end

function pensieve.ask_then_write_daily()
    local dirname = nil
    vim.ui.input(
        {
            prompt = "Path: ",
            completion = "dir"
        },
        function(input) dirname = input end
    )
    pensieve.write_daily(dirname)
end
pensieve.options = nil
return pensieve
