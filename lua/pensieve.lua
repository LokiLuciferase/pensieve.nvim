local Utils = require("pensieve/utils")
local Repo = require("pensieve/repo")
local Skeleton = require("pensieve/skeleton")
local pensieve = {}

local function with_defaults(options)
    return {
        default_encryption = options.default_encryption or "gocryptfs",
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
    vim.api.nvim_create_user_command(
        "PensieveInit",
        pensieve.ask_then_init_repo,
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
    if not repo:is_open() then
        vim.api.nvim_err_writeln("Could not open repo.")
        return
    end

    -- set up augroup to close repo on nvim exit
    local cwd_pre = vim.fn.getcwd()
    local group = vim.api.nvim_create_augroup("pensieve", {clear = false})
    vim.api.nvim_create_autocmd('VimLeavePre', {group = group, callback = function() vim.fn.chdir(cwd_pre) repo:close() end})

    local daily_path = repo:get_daily_path()
    if not Utils.file_exists(daily_path) then
        vim.fn.writefile(Skeleton.get_daily(), daily_path, "s")
    end
    vim.cmd("e " .. daily_path)
    Skeleton.assume_default_position()
end

function pensieve.init_repo(dirname)
    if not pensieve.is_configured() then
        return
    end
    if not dirname then
        vim.api.nvim_err_writeln("The passed directory is not readable.")
        return
    end
    local repo = Repo:new(dirname, pensieve.options)
    repo:init_on_disk()
end

function pensieve.ask_then_init_repo()
    local dirname = nil
    vim.ui.input(
        {
            prompt = "Path: ",
            completion = "dir"
        },
        function(input) dirname = input end
    )
    pensieve.init_repo(dirname)
    vim.api.nvim_out_write("Initialized repo in " .. dirname)
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
