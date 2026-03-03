local Games = {
    [7336302630] = "https://raw.githubusercontent.com/skibidihook/skibidihook/main/Project%20Delta/obfuscated.lua",
    [113217312262185] = "https://raw.githubusercontent.com/skibidihook/skibidihook/main/Project%20Delta/obfuscated.lua"
}

local LoaderUrl = Games[game.PlaceId]
if LoaderUrl then
    loadstring(game:HttpGet(LoaderUrl))()
end