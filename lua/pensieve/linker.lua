local json = require("pensieve/json")
Linker = {}


function Linker.load_aliases(aliases_path)
    local aliases = {}
    local file = io.open(aliases_path, "r")
    if file then
        local contents = file:read("*a")
        file:close()
        aliases = json.decode(contents)
    end
    return aliases
end


function Linker.invert_aliases(aliases)
    local inverted = {}
    for entity, alias_table in pairs(aliases) do
        for alias, _ in pairs(alias_table) do
            inverted[alias] = entity
        end
    end
    return inverted
end


function Linker.parse_link_args(args)
    if #args == 0 then
        -- this is an error
        vim.api.nvim_err_writeln("No arguments passed.")
        return {}
    elseif #args == 1 then
        return args
    else
        if string.match(args[1], '/') then
            -- we want to set a new alias for the given group/entity
            return {table.remove(args, 1), table.concat(args, ' ')}
        else
            -- we want to retrieve an entity using a multi-word alias
            return {table.concat(args, ' ')}
        end
    end
end


function Linker:new(repopath)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    self.aliases_path = repopath .. "/meta/aliases.json"
    self.entities_to_aliases = Linker.load_aliases(self.aliases_path)
    self.aliases_to_entities = Linker.invert_aliases(self.entities_to_aliases)
    local n = 0
    self.all_aliases = {}
    for k,v in pairs(self.aliases_to_entities) do
        n = n + 1
        self.all_aliases[n] = k
    end
    return o
end


function Linker:dump_aliases()
    local file = io.open(self.aliases_path, "w")
    if file then
        file:write(json.encode(self.entities_to_aliases))
        file:close()
    end
end


function Linker:alias(entity, alias)
    local entity_wo_ext = entity:match("(.+)%..+$")
    if entity_wo_ext then
        entity = entity_wo_ext
    end
    if not string.match(entity, "/") then
        vim.api.nvim_err_writeln(
            "Cannot create alias without entity category: " .. alias .. " -> " .. entity
        )
        return false
    end
    if self.aliases_to_entities[alias] then
        vim.api.nvim_err_writeln(
            "Alias already exists: " .. alias .. " -> " .. self.aliases_to_entities[alias]
        )
        return false
    end
    if self.entities_to_aliases[entity] then
        self.entities_to_aliases[entity][alias] = 1
    else
        self.entities_to_aliases[entity] = {}
        self.entities_to_aliases[entity][alias] = 1
    end
    self.aliases_to_entities[alias] = entity
    Linker:dump_aliases()
    return true
end


function Linker:unalias(alias)
    local entity = self.aliases_to_entities[alias]
    if entity then
        self.entities_to_aliases[entity][alias] = nil
        self.aliases_to_entities[alias] = nil
    end
    Linker:dump_aliases()
end


function Linker:autocomplete_alias(prefix)
    local matches = {}
    for _, alias in ipairs(self.all_aliases) do
        if string.find(alias, prefix) == 1 then
            table.insert(matches, alias)
        end
    end
    return matches
end


return Linker
