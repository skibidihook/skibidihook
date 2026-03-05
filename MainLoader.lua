local Games = {
    [7336302630] = "https://raw.githubusercontent.com/skibidihook/skibidihook/main/Games/Project%20Delta/obfuscated.lua",
    [113217312262185] = "https://raw.githubusercontent.com/skibidihook/skibidihook/main/Games/Scp%Retrobreach/obfuscated.lua",
    [109397169461300] = "https://raw.githubusercontent.com/skibidihook/skibidihook/main/Games/Sniper%Duels/obfuscated.lua"
}

local LoaderUrl = Games[game.PlaceId]
if LoaderUrl then
    loadstring(game:HttpGet(LoaderUrl))()
end