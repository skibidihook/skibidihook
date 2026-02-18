print("CRACKED BY SIGMA X CORD X ACHE")
local Repo = "https://raw.githubusercontent.com/ghgghigher-prog/Silicon-leak/main/Clones/Silicone/"
local Games = {
    [286090429] = Repo .. "Arsenal.lua",
    [7711635737] = Repo .. "EmergencyHamburg.lua",
    [891852901] = Repo .. "Greenville.lua",
    [136801880565837] = Repo .. "Flick.lua",
    [94539932414164] = Repo .. "MojaveValley.lua",
    [142823291] = Repo .. "MurderMystery2.lua",
    [6161235818] = Repo .. "Twisted.lua",
    [5104202731] = Repo .. "SouthwestFlorida.lua",
    [89570211388424] = Repo .. "CentralKansas.lua"
}
local LoaderUrl = Games[game.PlaceId]
if LoaderUrl then
    loadstring(game:HttpGet(LoaderUrl))()
end