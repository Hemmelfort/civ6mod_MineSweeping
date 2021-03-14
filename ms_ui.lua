
print('Mine Sweeper UI is loading.')

local m_DigPlotAction = Input.GetActionId('DigPlot')
local m_MarkPlotAction = Input.GetActionId('MarkPlot')
local m_MSTestAction = Input.GetActionId('MSTest')

local pCurPlayer
local pCurUnit



function MSTest()
    ExposedMembers.MineSweeper.MSTest()
end


function DigPlot()
    --local pUnit = UI.GetHeadSelectedUnit()
    if pCurUnit ~= nil then
        ExposedMembers.MineSweeper.DigPlot(pCurUnit:GetX(), pCurUnit:GetY())
    end
end


function MarkPlot()
    if pCurUnit ~= nil then
        ExposedMembers.MineSweeper.MarkPlot(pCurUnit:GetX(), pCurUnit:GetY())
    end

end


function OnInputActionTriggered(iActionID)
    if (iActionID == m_DigPlotAction) then
        DigPlot()
    elseif(iActionID == m_MarkPlotAction) then
        MarkPlot()
    elseif(iActionID == m_MSTestAction) then
        MSTest()
    end
end


function OnLoadGameViewStateDone()
    pCurPlayer = Players[Game.GetLocalPlayer()];
--    for i, unit in pCurPlayer:GetUnits():Members() do
--        if 
--    end
end


function OnUnitSelectionChanged(iPlayerID, iUnitID, iPlotX, iPlotY, iPlotZ, bSelected, bEditable)
    if bSelected then
        pCurUnit = UnitManager.GetUnit(iPlayerID, iUnitID)
        
--        if pCurUnit:GetType() ~= m_SettlerIndex then
--            Controls.SettleButtonGrid:SetHide(true)
--            return
--        end
        
    end
end


Events.InputActionTriggered.Add(OnInputActionTriggered)
Events.LoadGameViewStateDone.Add(OnLoadGameViewStateDone)
Events.UnitSelectionChanged.Add(OnUnitSelectionChanged)

