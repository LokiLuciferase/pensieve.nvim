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

function Utils.parse_date_abbrev(abbr)
    if abbr == nil or abbr == 'today' then
        return os.date("%Y-%m-%d")
    elseif abbr:sub(1, 1) == 't' then
        if abbr:sub(2, 2) == '-' then
            local days = tonumber(abbr:sub(3))
            return os.date("%Y-%m-%d", os.time() - (days * 86400))
        elseif abbr:sub(2, 2) == '+' then
            local days = tonumber(abbr:sub(3))
            return os.date("%Y-%m-%d", os.time() + (days * 86400))
        else
            error("Invalid date abbreviation: " .. abbr)
        end
    else
        return abbr
    end
end

return Utils
