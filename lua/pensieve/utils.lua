Utils = {}

function Utils.file_exists(f)
    local rv = vim.fn.filereadable(f)
    if rv == 1 then
        return true
    else
        return false
    end
end

function Utils.splitstring(inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    local t = {}
    for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
        table.insert(t, str)
    end
    return t
end

return Utils
