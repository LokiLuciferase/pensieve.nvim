GocryptFS = {}

function GocryptFS.Open(dir_path, password)
    local cmd = "gocryptfs"
        .. " -i '1m' "
        .. dir_path
        .. "/cipher"
        .. " "
        .. dir_path
        .. "/plain"
    local f = io.popen(cmd, "w")
    f:write(password)
    f:close()
end

function GocryptFS.IsOpen(dir_path)
    local cmd = 'test -z "$(ls -A ' .. dir_path .. '/plain)"'
    local retval = os.execute(cmd) / 256
    return retval
end

function GocryptFS.Close(dir_path)
    local f = os.execute(
        "fusermount -u " .. dir_path .. "/plain"
    )
end

return GocryptFS
