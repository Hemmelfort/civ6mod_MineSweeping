

local m_iFeatureForest = GameInfo.Features['FEATURE_JUNGLE'].Index
local m_iResourceMine = GameInfo.Resources['RESOURCE_URANIUM'].Index

local m_AmountTable = {}




function MSTest()
    Detonate()
end



function InitializeNewGame()
    print('InitializeNewGame in MineSweeper.')
    
    local pCurPlayerVisibility = PlayersVisibility[Game.GetLocalPlayer()]
    
    if pCurPlayerVisibility ~= nil then
        for iPlotIndex = 0, Map.GetPlotCount()-1, 1 do
            pCurPlayerVisibility:ChangeVisibilityCount(iPlotIndex, 1);
            
            local pPlot = Map.GetPlotByIndex(iPlotIndex)
            if not pPlot:IsWater() then
                TerrainBuilder.SetFeatureType(pPlot, m_iFeatureForest)
                
                if (math.random() < 0.2) then
                    AddMine(pPlot)
                end
            end
            
        end
    end
    
end


function AddMine(pPlot)
    ResourceBuilder.SetResourceType(pPlot, m_iResourceMine, 1)
    local tNeighborPlots = Map.GetAdjacentPlots(pPlot:GetX(), pPlot:GetY())
    for _, plot in ipairs(tNeighborPlots) do
        if not plot:IsWater() then
            local i = plot:GetIndex()
            local v = m_AmountTable[i]
            if (v == nil) then
                m_AmountTable[i] = 1
            else
                m_AmountTable[i] = v + 1
            end
        end
    end
end



function DigPlot(iX, iY)
    local pPlot = Map.GetPlot(iX, iY)
    if (pPlot ~= nil) then
        TerrainBuilder.SetFeatureType(pPlot, -1)
        
        if (pPlot:GetResourceType() == m_iResourceMine) then
            Detonate()
        end
    end
end

function MarkPlot(iX, iY)
    local pPlot = Map.GetPlot(iX, iY)
    if (pPlot ~= nil) then
        TerrainBuilder.SetFeatureType(pPlot, m_iFeatureForest)
    end
end


function Detonate()
    local playerTechs = Players[Game.GetLocalPlayer()]:GetTechs();
    playerTechs:SetTech(GameInfo.Technologies["TECH_COMBINED_ARMS"].Index, true)
end





LuaEvents.NewGameInitialized.Add(InitializeNewGame);

if ExposedMembers.MineSweeper == nil then
    ExposedMembers.MineSweeper = {}
end

ExposedMembers.MineSweeper.DigPlot = DigPlot
ExposedMembers.MineSweeper.MarkPlot = MarkPlot
ExposedMembers.MineSweeper.MSTest = MSTest

