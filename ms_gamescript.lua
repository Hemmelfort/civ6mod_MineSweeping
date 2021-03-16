

local m_iFeatureForest = GameInfo.Features['FEATURE_FOREST'].Index
local m_iResourceMine = GameInfo.Resources['RESOURCE_URANIUM'].Index
local m_iImprovementFlag = GameInfo.Improvements['IMPROVEMENT_FORT'].Index

local m_AmountTable = {}
local m_tNumberToResource = {
    [1] = GameInfo.Resources['RESOURCE_RICE'].Index,
    [2] = GameInfo.Resources['RESOURCE_WHEAT'].Index,
    [3] = GameInfo.Resources['RESOURCE_SUGAR'].Index,
    [4] = GameInfo.Resources['RESOURCE_SALT'].Index,
    [5] = GameInfo.Resources['RESOURCE_SILVER'].Index,
    [6] = GameInfo.Resources['RESOURCE_COTTON'].Index,
}

local m_bFirstTry = true


function GetResourceByNumber(num)
    local res = m_tNumberToResource[num]
    if (res ~= nil) then
        return res
    else
        return GameInfo.Resources['RESOURCE_WINE'].Index
    end
end



function MSTest()
    Detonate()
    
    local tContinents = Map.GetContinentsInUse()
    for i, eContinent in ipairs(tContinents) do
        local tContinentPlots = Map.GetContinentPlots(eContinent)   -- tContinentPlots 存放的是 iPlotIndex

        for _, plot in ipairs(tContinentPlots) do
            local pPlot = Map.GetPlotByIndex(plot)
            -- use pPlot here
            
            local num = m_AmountTable[pPlot:GetIndex()]
            if (num ~= nil) then
                local res = GetResourceByNumber(num)
                ResourceBuilder.SetResourceType(pPlot, res, 1)
            end
        end
    end
end


function RevealEmptyPlotsNearby(pPlot)
    local tNeighborPlots = Map.GetAdjacentPlots(pPlot:GetX(), pPlot:GetY())
    for _, plot in ipairs(tNeighborPlots) do
        if (plot:GetFeatureType() == m_iFeatureForest) and (not plot:IsWater()) then
            --local i = plot:GetIndex()
            DigPlot(plot:GetX(), plot:GetY())
--            if (m_AmountTable[i] == nil)then
--                Game.AddWorldViewText(0, 'empty', plot:GetX(), plot:GetY())
--            end
        end
        --if has been revealed: pass
    end
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
                
                if (math.random() < 0.1) then
                    AddMine(pPlot)
                end
            end
            
        end
    end
    
end


function AddMine(pPlot)
    ResourceBuilder.SetResourceType(pPlot, m_iResourceMine, 1)
    m_AmountTable[pPlot:GetIndex()] = nil
    
    local tNeighborPlots = Map.GetAdjacentPlots(pPlot:GetX(), pPlot:GetY())
    for _, plot in ipairs(tNeighborPlots) do
        if (not plot:IsWater())
        and (plot:GetResourceType() == -1)
        then
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
        if (pPlot:GetResourceType() == m_iResourceMine) then
            if m_bFirstTry then
                m_bFirstTry = false
                Game.AddWorldViewText(0, "don't dig here", iX, iY)
            else
                Detonate()
            end
            return
        end
        
        TerrainBuilder.SetFeatureType(pPlot, -1)
        
        local num = m_AmountTable[pPlot:GetIndex()]
        if (num ~= nil) then
            local res = GetResourceByNumber(num)
            ResourceBuilder.SetResourceType(pPlot, res, 1)
        else
            RevealEmptyPlotsNearby(pPlot)
        end
        
        if (pPlot:GetImprovementType() == m_iImprovementFlag) then
            ImprovementBuilder.SetImprovementType(pPlot, -1, -1)
        end
    end
end

function MarkPlot(iX, iY)
    local pPlot = Map.GetPlot(iX, iY)
    if (pPlot ~= nil) then
        if (pPlot:GetImprovementType() == m_iImprovementFlag) then
            ImprovementBuilder.SetImprovementType(pPlot, -1, -1)
        else
            ImprovementBuilder.SetImprovementType(pPlot, m_iImprovementFlag, Game.GetLocalPlayer())
        end
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

