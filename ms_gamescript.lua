

local m_iFeatureForest = GameInfo.Features['FEATURE_FOREST'].Index
local m_iResourceMine = GameInfo.Resources['RESOURCE_URANIUM'].Index
local m_iImprovementFlag = GameInfo.Improvements['IMPROVEMENT_FORT'].Index
local m_iImprovementMine = GameInfo.Improvements['IMPROVEMENT_OIL_WELL'].Index

local m_tNumberToResource = {
    [1] = GameInfo.Resources['RESOURCE_RICE'].Index,
    [2] = GameInfo.Resources['RESOURCE_WHEAT'].Index,
    [3] = GameInfo.Resources['RESOURCE_SUGAR'].Index,
    [4] = GameInfo.Resources['RESOURCE_SALT'].Index,
    [5] = GameInfo.Resources['RESOURCE_SILVER'].Index,
    [6] = GameInfo.Resources['RESOURCE_COTTON'].Index,
}

local m_AmountTable = {}
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
    --Detonate()
    Replay()
end


function RevealEmptyPlotsNearby(pPlot)
    local tNeighborPlots = Map.GetAdjacentPlots(pPlot:GetX(), pPlot:GetY())
    for _, plot in ipairs(tNeighborPlots) do
        if (plot:GetFeatureType() == m_iFeatureForest) and (not plot:IsWater()) then
            -- 空白格位旁边的地方直接挖就是了
            DigPlot(plot:GetX(), plot:GetY())
        end
    end
end


function InitializeNewGame()
    print('InitializeNewGame in MineSweeper.')
    
    -- 开全图视野
    local pCurPlayerVisibility = PlayersVisibility[Game.GetLocalPlayer()]
    if pCurPlayerVisibility ~= nil then
        for iPlotIndex = 0, Map.GetPlotCount()-1, 1 do
            pCurPlayerVisibility:ChangeVisibilityCount(iPlotIndex, 1);
        end
    end
    
    -- 布置战场
    Replay()
    
end


function Replay()
    m_bFirstTry = true
    m_AmountTable = {}
    
    -- 清除改良设施、资源，然后种树
    local tContinents = Map.GetContinentsInUse()
    for i, eContinent in ipairs(tContinents) do
        local tContinentPlots = Map.GetContinentPlots(eContinent)

        for _, plot in ipairs(tContinentPlots) do
            local pPlot = Map.GetPlotByIndex(plot)
            if (not pPlot:IsWater()) then
                ImprovementBuilder.SetImprovementType(pPlot, -1, -1)
                ResourceBuilder.SetResourceType(pPlot, -1)
                TerrainBuilder.SetFeatureType(pPlot, m_iFeatureForest)
            end
        end
        
        for _, plot in ipairs(tContinentPlots) do
            if (math.random() < 0.1) then
                local pPlot = Map.GetPlotByIndex(plot)
                AddMine(pPlot)
            end
        end
    end
    
end



function AddMine(pPlot)
    if pPlot:IsWater() then
        return
    end
    
    ResourceBuilder.SetResourceType(pPlot, m_iResourceMine, 1)
    m_AmountTable[pPlot:GetIndex()] = nil   --有雷的格位不能有数字
    
    -- 在地雷周围记录数字
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
    if (pPlot == nil) or pPlot:IsWater() 
    or (pPlot:GetFeatureType() ~= m_iFeatureForest) then
        return
    end

    -- 挖到雷了
    if (pPlot:GetResourceType() == m_iResourceMine) then
        if m_bFirstTry then
            m_bFirstTry = false
            Game.AddWorldViewText(0, "don't dig here", iX, iY)
        else
            Detonate()
        end
        return
    end
    
    -- 如果格位已经标记过了，那就只清除标记
    if (pPlot:GetImprovementType() == m_iImprovementFlag) then
        ImprovementBuilder.SetImprovementType(pPlot, -1, -1)
        return
    end
    
    -- 如果有数字就显示出来，没有则清除周围其他空白格位
    TerrainBuilder.SetFeatureType(pPlot, -1)
    local num = m_AmountTable[pPlot:GetIndex()]
    if (num ~= nil) then
        local res = GetResourceByNumber(num)
        ResourceBuilder.SetResourceType(pPlot, res, 1)
    else
        RevealEmptyPlotsNearby(pPlot)
    end
end

function MarkPlot(iX, iY)
    local pPlot = Map.GetPlot(iX, iY)
    if (pPlot ~= nil) and (pPlot:GetFeatureType() == m_iFeatureForest) then
        if (pPlot:GetImprovementType() == m_iImprovementFlag) then
            ImprovementBuilder.SetImprovementType(pPlot, -1, -1)
        else
            ImprovementBuilder.SetImprovementType(pPlot, m_iImprovementFlag, Game.GetLocalPlayer())
        end
    end
end


function Detonate()
    local tContinents = Map.GetContinentsInUse()
    for i, eContinent in ipairs(tContinents) do
        local tContinentPlots = Map.GetContinentPlots(eContinent)

        for _, plot in ipairs(tContinentPlots) do
            local pPlot = Map.GetPlotByIndex(plot)
            if (pPlot:GetResourceType() == m_iResourceMine) then
                ImprovementBuilder.SetImprovementType(pPlot, m_iImprovementMine, Game.GetLocalPlayer())
            else
                DigPlot()
            end
        end
    end
end





LuaEvents.NewGameInitialized.Add(InitializeNewGame);

if ExposedMembers.MineSweeper == nil then
    ExposedMembers.MineSweeper = {}
end

ExposedMembers.MineSweeper.DigPlot = DigPlot
ExposedMembers.MineSweeper.MarkPlot = MarkPlot
ExposedMembers.MineSweeper.MSTest = MSTest

