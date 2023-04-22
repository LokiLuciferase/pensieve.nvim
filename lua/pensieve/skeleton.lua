Skeleton = {}

function Skeleton.get_daily(datestr)
    local datestr = datestr or os.date("%Y-%m-%d")
    local header = "## " .. datestr
    local entry = "### Entry"
    local emo = "### Emotions"
    local rating = "### Rating"
    local tags = "### Tags"
    return {header, entry, "", emo, "", rating, "y/10", "", tags, "unclassified"}
end

function Skeleton.assume_default_position()
    vim.cmd("normal gg1jo")
    vim.cmd("startinsert")
end

return Skeleton
