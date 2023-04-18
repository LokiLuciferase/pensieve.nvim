require "pensieve.crypt"

Repo = {}

function Repo.resolvePath(dirpath)
    if pensieve_encryption == "gocryptfs" then
        return dirpath .. "/plain"
    else
        return dirpath
    end
end

function Repo.init(dirpath)
    print(dirpath)
    local dirpath = Repo.resolvePath(dirpath)
    print(dirpath)
    os.execute("mkdir -p " .. dirpath .. "/entries")
    os.execute("mkdir -p " .. dirpath .. "/meta")
    os.execute("touch " .. dirpath .. "/meta/repo.json")
end

function Repo.isOpen(dirpath)
    local dirpath = Repo.resolvePath(dirpath)
    local cmd = 'test ! -f ' .. dirpath .. '/meta/repo.json'
    local retval = os.execute(cmd) / 256
    return retval
end

function Repo.open(dirpath)
    if pensieve_encryption == "gocryptfs" then
        -- TODO: should prompt for pw here
        pw = "test"
        GocryptFS.Open(dirpath, pw)
        local dirpath = Repo.resolvePath(dirpath)
    end
    return Repo.isOpen(dirpath)
end

function Repo.close(dirpath)
    if pensieve_encryption == "gocryptfs" then
        GocryptFS.Close(dirpath)
    end
end

return Repo
