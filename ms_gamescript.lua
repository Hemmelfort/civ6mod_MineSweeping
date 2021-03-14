

local iFeatureForest = GameInfo.Features['FEATURE_JUNGLE'].Index


function InitializeNewGame()
    print('InitializeNewGame in MineSweeper.')
    
    local pCurPlayerVisibility = PlayersVisibility[Game.GetLocalPlayer()]
    
    if pCurPlayerVisibility ~= nil then
        for iPlotIndex = 0, Map.GetPlotCount()-1, 1 do
            pCurPlayerVisibility:ChangeVisibilityCount(iPlotIndex, 1);
            
            local pPlot = Map.GetPlotByIndex(iPlotIndex)
            if not pPlot:IsWater() then
                TerrainBuilder.SetFeatureType(pPlot, iFeatureForest)
            end
            
        end
    end
    
    LayMines();
end




function LayMines()
	local pPlayer = Players[Game.GetLocalPlayer()];
	local playerUnits = pPlayer:GetUnits();
	for i, unit in playerUnits:Members() do
        local iX = unit:GetX()
        local iY = unit:GetY()
        local pPlot = Map.GetPlot(iX, iY)
        ResourceBuilder.SetResourceType(pPlot, 1, 1);
        break
	end
end


function DigPlot(iX, iY)
    local pPlot = Map.GetPlot(iX, iY)
    if (pPlot ~= nil) then
        TerrainBuilder.SetFeatureType(pPlot, -1)
    end
end

function MarkPlot(iX, iY)
    local pPlot = Map.GetPlot(iX, iY)
    if (pPlot ~= nil) then
        TerrainBuilder.SetFeatureType(pPlot, iFeatureForest)
    end
end



LuaEvents.NewGameInitialized.Add(InitializeNewGame);

if ExposedMembers.MineSweeper == nil then
    ExposedMembers.MineSweeper = {}
end

ExposedMembers.MineSweeper.DigPlot = DigPlot
ExposedMembers.MineSweeper.MarkPlot = MarkPlot

