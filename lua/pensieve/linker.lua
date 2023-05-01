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
    if self.entities_to_aliases[entity] then
        self.entities_to_aliases[entity][alias] = 1
    else
        self.entities_to_aliases[entity] = {}
        self.entities_to_aliases[entity][alias] = 1
    end
    self.aliases_to_entities[alias] = entity
    Linker:dump_aliases()
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
