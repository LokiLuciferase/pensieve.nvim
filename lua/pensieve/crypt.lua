GocryptFS = {}

function GocryptFS.Open(dir_path, password, timeout)
    local cmd = "gocryptfs"
        .. " -i '"
        .. (timeout or '1m')
        .. "' "
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
    local cmd = "fusermount -uz " .. dir_path .. "/plain" .. " 2>&1"
    local handle = io.popen(cmd)
    local out = handle:read("*a")
    print("closed " .. dir_path .. ":" .. out)
end

return GocryptFS
