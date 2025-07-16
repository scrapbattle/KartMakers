local KartMakers = {
    Playground = {}
}

KartMakers.Playground.Example = function()
    tm.os.Log("Test")
end

tm.os.Log("KartMakers.Playground is now loaded")
return KartMakers