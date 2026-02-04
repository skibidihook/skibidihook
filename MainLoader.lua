local Games = {
    [7336302630] = "https://raw.githubusercontent.com/skibidihook/skibidihook/refs/heads/main/Project%20Delta/obfuscated.lua"
}

local LoaderUrl = Games[game.PlaceId]
if LoaderUrl then
    loadstring(game:HttpGet(LoaderUrl))()
end