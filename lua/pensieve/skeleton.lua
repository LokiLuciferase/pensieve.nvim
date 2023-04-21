Skeleton = {}

function Skeleton.get_daily(datestr)
    local datestr = datestr or os.date("%Y-%m-%d")
    local header = "## " .. datestr
    local entry = "### Entry"
    local emo = "### Emotions"
    local rating = "### Rating"
    local notes = "### Notes"
    return {header, entry, "", emo, "- x", "", rating, "y/10", "", notes}
end

function Skeleton.assume_default_position()
    vim.cmd("normal gg1jo")
    vim.cmd("startinsert")
end

return Skeleton
