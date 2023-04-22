CapCheck = {}

function CapCheck.gocryptfs()
    local gocryptfs = io.popen("gocryptfs -version")
    local gocryptfs_version = gocryptfs:read("*a")
    gocryptfs:close()
    if gocryptfs_version == "" then
        return false
    else
        return true
    end
end

function CapCheck.vimwiki()
    local vwp = string.match(vim.o.runtimepath, "vimwiki")
    if vwp == nil then
        return false
    else
        return true
    end
end

function CapCheck:new()
    local o = {
        gocryptfs = CapCheck.gocryptfs(),
        vimwiki = CapCheck.vimwiki()
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

return CapCheck

