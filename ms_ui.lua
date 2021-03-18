
print('Mine Sweeper UI is loading.')

include("PopupDialog");

local m_DigPlotAction = Input.GetActionId('DigPlot')
local m_MarkPlotAction = Input.GetActionId('MarkPlot')
local m_MSTestAction = Input.GetActionId('MSTest')

local pCurPlayer
local pCurUnit



function MSTest()
    print('--------mstest---------------->')
    
    local popup = PopupDialogInGame:new("UnitCaptured")
    popup:AddTitle("title");
    popup:AddText("text")
    --popup:AddCheckBox(Locale.Lookup("LOC_REMEMBER_MY_CHOICE"), false, OnRememberChoice);
    popup:AddCustomButton("new game", function()
        ExposedMembers.MineSweeper.Replay()
    end);
    popup:AddCustomButton("test", function()
        ExposedMembers.MineSweeper.MSTest()
    end);
    popup:Open();
end


function DigPlot()
    if pCurUnit ~= nil then
        ExposedMembers.MineSweeper.DigPlot(pCurUnit:GetX(), pCurUnit:GetY())
        --ExposedMembers.MineSweeper.RestoreMovement(pCurPlayer:GetID(), pCurUnit:GetID())
        ExposedMembers.MineSweeper.CheckVictory()
    end
end


function MarkPlot()
    if pCurUnit ~= nil then
        ExposedMembers.MineSweeper.MarkPlot(pCurUnit:GetX(), pCurUnit:GetY())
        --ExposedMembers.MineSweeper.RestoreMovement(pCurPlayer:GetID(), pCurUnit:GetID())
        ExposedMembers.MineSweeper.CheckVictory()
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
    
    local ctrl = ContextPtr:LookUpControl("/InGame/UnitPanel/StandardActionsStack")
    Controls.MineSweeperActionButtons:ChangeParent(ctrl)
    Controls.DigButton:RegisterCallback(Mouse.eLClick, DigPlot)
    Controls.MarkButton:RegisterCallback(Mouse.eLClick, MarkPlot)
end


function OnUnitSelectionChanged(iPlayerID, iUnitID, iPlotX, iPlotY, iPlotZ, bSelected, bEditable)
    if bSelected then
        pCurUnit = UnitManager.GetUnit(iPlayerID, iUnitID)
    end
end


Events.InputActionTriggered.Add(OnInputActionTriggered)
Events.LoadGameViewStateDone.Add(OnLoadGameViewStateDone)
Events.UnitSelectionChanged.Add(OnUnitSelectionChanged)

LuaEvents.EndGameMenu_Closed.Add(
    function ()
        ExposedMembers.MineSweeper.Replay()
    end)






