

---------------------------------------
-- 
---------------------------------------

---------------------------------------
-- 
---------------------------------------

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

local m_sUnitReferee = "UNIT_WARRIOR"   --当裁判出现时，玩家获胜
local m_iLocalPlayer = Game.GetLocalPlayer()

local m_NumbersTable = {}   --记录格位周围的地雷数，索引为iPlotIndex
local m_bFirstTry = true    --是不是第一次下铲（保证第一次不能挖到雷）
local m_iMinesRemain = 0    --全图剩余未标记的地雷数


---------------------------------------
-- 判断table中是否含有某项
---------------------------------------
function IsIncluded(tab, value)
    for _, v in ipairs(tab) do
        if value == v then
            return true
        end
    end
    
    return false
end


---------------------------------------
-- 数字所对应的资源
---------------------------------------
function GetResourceByNumber(num)
    local res = m_tNumberToResource[num]
    if (res ~= nil) then
        return res
    else
        return GameInfo.Resources['RESOURCE_WINE'].Index
    end
end


---------------------------------------
-- 测试用的
---------------------------------------
function MSTest()
    --Detonate()
    print('ms test in gameplay script.')
end


---------------------------------------
-- 如果挖到的是空白（不含雷、不含数字），那就连带把周边其他空白也揪出来
---------------------------------------
function RevealEmptyPlotsNearby(pPlot)
    local tNeighborPlots = Map.GetAdjacentPlots(pPlot:GetX(), pPlot:GetY())
    for _, plot in ipairs(tNeighborPlots) do
        if (plot:GetFeatureType() == m_iFeatureForest) and (not plot:IsWater()) then
            -- 空白格位旁边的地方直接挖就是了
            DigPlot(plot:GetX(), plot:GetY())
        end
    end
end


---------------------------------------
-- 游戏初始化（硬开始）
---------------------------------------
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


---------------------------------------
-- 重新开始一盘游戏（软开始）
---------------------------------------
function Replay()
    m_bFirstTry = true
    m_NumbersTable = {}
    m_iMinesRemain = 0
    
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
    end
    
    -- 移除裁判
    local pPlayer = Players[m_iLocalPlayer]
    if (pPlayer ~= nil) then
        for i, unit in pPlayer:GetUnits():Members() do
            local unitInfo = GameInfo.Units[unit:GetType()];
            if (unitInfo) then
                if (unitInfo.UnitType == m_sUnitReferee) then
                    UnitManager.Kill(unit)
                end
            end
        end
	end
    
end



---------------------------------------
-- 在一个格位里面放入地雷，影响到周围格位的数字
---------------------------------------
function AddMine(pPlot)
    if pPlot:IsWater() then
        return
    end
    
    ResourceBuilder.SetResourceType(pPlot, m_iResourceMine, 1)
    m_NumbersTable[pPlot:GetIndex()] = nil   --有雷的格位不能有数字
    m_iMinesRemain = m_iMinesRemain + 1
    
    -- 在地雷周围记录数字
    local tNeighborPlots = Map.GetAdjacentPlots(pPlot:GetX(), pPlot:GetY())
    for _, plot in ipairs(tNeighborPlots) do
        if (not plot:IsWater())
        and (plot:GetResourceType() == -1)
        then
            local i = plot:GetIndex()
            local v = m_NumbersTable[i]
            if (v == nil) then
                m_NumbersTable[i] = 1
            else
                m_NumbersTable[i] = v + 1
            end
        end
    end
end


---------------------------------------
-- 对全图布雷，可以设置禁雷区
---------------------------------------
function AddMines(tInvalidPlots : table)
    local tContinents = Map.GetContinentsInUse()
    for i, eContinent in ipairs(tContinents) do
        local tContinentPlots = Map.GetContinentPlots(eContinent)
        
        for _, plot in ipairs(tContinentPlots) do
            if (not IsIncluded(tInvalidPlots, plot)) and (math.random() < 0.15) then
                local pPlot = Map.GetPlotByIndex(plot)
                AddMine(pPlot)
            end
        end
    end
end


---------------------------------------
-- 挖一个格位
---------------------------------------
function DigPlot(iX, iY)
    local pPlot = Map.GetPlot(iX, iY)
    if (pPlot == nil) or pPlot:IsWater() 
    or (pPlot:GetFeatureType() ~= m_iFeatureForest) then
        return
    end

    -- 保证第一次挖到的是空地，所以要等玩家开挖后再布雷
    if m_bFirstTry then
        -- 当前格位及其周围格位不能有雷，才能保证当前格位必定是空地
        local tInvalidPlots = {}
        local tNeighborPlots = Map.GetAdjacentPlots(pPlot:GetX(), pPlot:GetY())
        for _, plot in ipairs(tNeighborPlots) do
            table.insert(tInvalidPlots, plot:GetIndex())
        end
        table.insert(tInvalidPlots, pPlot:GetIndex())
        
        AddMines(tInvalidPlots)
        m_bFirstTry = false
    end
    
    -- 挖到雷了
    if (pPlot:GetResourceType() == m_iResourceMine) then
        Detonate()
        return
    end
    
    -- 如果格位已经标记过了，那就只清除标记
    if (pPlot:GetImprovementType() == m_iImprovementFlag) then
        ImprovementBuilder.SetImprovementType(pPlot, -1, -1)
        return
    end
    
    -- 如果有数字就显示出来，没有则清除周围其他空白格位
    TerrainBuilder.SetFeatureType(pPlot, -1)
    local num = m_NumbersTable[pPlot:GetIndex()]
    if (num ~= nil) then
        local res = GetResourceByNumber(num)
        ResourceBuilder.SetResourceType(pPlot, res, 1)
    else
        RevealEmptyPlotsNearby(pPlot)
    end
end


---------------------------------------
-- 标记一个格位
---------------------------------------
function MarkPlot(iX, iY)
    local pPlot = Map.GetPlot(iX, iY)
    if (pPlot ~= nil) then
        if (pPlot:GetImprovementType() == m_iImprovementFlag) then
            ImprovementBuilder.SetImprovementType(pPlot, -1, -1)
            TerrainBuilder.SetFeatureType(pPlot, m_iFeatureForest)
            m_iMinesRemain = m_iMinesRemain + 1
        else
            TerrainBuilder.SetFeatureType(pPlot, -1)
            ImprovementBuilder.SetImprovementType(pPlot, m_iImprovementFlag, Game.GetLocalPlayer())
            m_iMinesRemain = m_iMinesRemain - 1
        end
    end
end


---------------------------------------
-- 引爆地雷，游戏结束
---------------------------------------
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
    ExposedMembers.MineSweeper.GameOver()
end


---------------------------------------
-- 判断是否应该获胜
---------------------------------------
function CheckVictory()
    -- 先确定所有格位均开发完毕
    local tContinents = Map.GetContinentsInUse()
    for i, eContinent in ipairs(tContinents) do
        local tContinentPlots = Map.GetContinentPlots(eContinent)

        for _, plot in ipairs(tContinentPlots) do
            local pPlot = Map.GetPlotByIndex(plot)
            if (pPlot:GetFeatureType() == m_iFeatureForest) then
                return
            end
        end
    end
    
    -- 如果已经标记完所有的格位，再判断标记对不对
    for i, eContinent in ipairs(tContinents) do
        local tContinentPlots = Map.GetContinentPlots(eContinent)

        for _, plot in ipairs(tContinentPlots) do
            local pPlot = Map.GetPlotByIndex(plot)
            if (pPlot:GetImprovementType() == m_iImprovementFlag)
            and (pPlot:GetResourceType() ~= m_iResourceMine) then
                Detonate()
            end
        end
    end

    local requirementSetID = Game.GetVictoryRequirements(Players[m_iLocalPlayer]:GetTeam(), 'VICTORY_SWEPT');
    if (requirementSetID ~= nil) and (requirementSetID ~= -1) then
        UnitManager.InitUnitValidAdjacentHex(m_iLocalPlayer, m_sUnitReferee, 0, 0, 1)
    else
        ExposedMembers.MineSweeper.GameWon()
    end
end


---------------------------------------
-- 获取剩余未标记的雷数（主要给UI界面用来显示）
---------------------------------------
function GetMinesRemain()
    return m_iMinesRemain
end


---------------------------------------
-- 恢复单位移动力
---------------------------------------
function RestoreMovement(iPlayerID, iUnitID)
    local pUnit = UnitManager.GetUnit(iPlayerID, iUnitID);
    UnitManager.RestoreMovement(pUnit)
end


LuaEvents.NewGameInitialized.Add(InitializeNewGame);


if ExposedMembers.MineSweeper == nil then
    ExposedMembers.MineSweeper = {}
end

ExposedMembers.MineSweeper.DigPlot = DigPlot
ExposedMembers.MineSweeper.MarkPlot = MarkPlot
ExposedMembers.MineSweeper.MSTest = MSTest
ExposedMembers.MineSweeper.RestoreMovement = RestoreMovement
ExposedMembers.MineSweeper.CheckVictory = CheckVictory
ExposedMembers.MineSweeper.Replay = Replay
ExposedMembers.MineSweeper.GetMinesRemain = GetMinesRemain



