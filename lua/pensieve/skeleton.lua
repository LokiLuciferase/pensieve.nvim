Skeleton = {}

function Skeleton.get_daily()
    local header = "## " .. os.date("%Y-%m-%d")
    local entry = "### Entry"
    local emo = "### Emotions"
    local rating = "### Rating"
    local notes = "### Notes"
    return {header, entry, "", emo, "- x", "", rating, "x/10", "", notes}
end

function Skeleton.assume_default_position()
    vim.cmd("normal gg1jo")
    vim.cmd("startinsert")
end

return Skeleton
