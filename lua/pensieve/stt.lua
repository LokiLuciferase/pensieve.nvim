STT = {}


function STT:get_text()
    local handle = io.popen("termux-speech-to-text")
    local text = handle:read("*a")
    return text
end


return STT
