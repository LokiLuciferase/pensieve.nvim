GocryptFS = {}

function GocryptFS.init(dir_path, password_v1, password_v2)
    local cmd = "gocryptfs"
        .. " -init "
        .. dir_path
        .. "/cipher"
    local f = io.popen(cmd, "w")
    f:write(password_v1 .. "\n" .. password_v2)
    f:close()
end

function GocryptFS.open(dir_path, password, timeout)
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

function GocryptFS.is_open(dir_path)
    local cmd = 'test -z "$(ls -A ' .. dir_path .. '/plain)"'
    local retval = os.execute(cmd) / 256
    return retval
end

function GocryptFS.close(dir_path)
    local cmd = "fusermount -uz " .. dir_path .. "/plain" .. " 2>&1"
    local handle = io.popen(cmd)
    local out = handle:read("*a")
end

return GocryptFS
