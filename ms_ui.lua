
print('Mine Sweeper UI is loading.')

include("PopupDialog");



local m_DigPlotAction = Input.GetActionId('DigPlot')
local m_MarkPlotAction = Input.GetActionId('MarkPlot')
local m_MSTestAction = Input.GetActionId('MSTest')

local m_bGameOver = false
local m_bTipShown = false

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
        m_bGameOver = false
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
        local i = ExposedMembers.MineSweeper.GetMinesRemain()
        Controls.MineRemain:SetText(tostring(i))
    end
end


function MarkPlot()
    if pCurUnit ~= nil then
        ExposedMembers.MineSweeper.MarkPlot(pCurUnit:GetX(), pCurUnit:GetY())
        --ExposedMembers.MineSweeper.RestoreMovement(pCurPlayer:GetID(), pCurUnit:GetID())
        ExposedMembers.MineSweeper.CheckVictory()
        local i = ExposedMembers.MineSweeper.GetMinesRemain()
        Controls.MineRemain:SetText(tostring(i))
    end

end


function GameOver()
    if (m_bGameOver == true) then
        return
    end
    
    m_bGameOver = true
    
    local popup = PopupDialogInGame:new("UnitCaptured")
    popup:AddTitle(Locale.Lookup('LOC_MINESWEEPER_GAMEOVER_TITLE'))
    popup:AddText(Locale.Lookup('LOC_MINESWEEPER_GAMEOVER_TEXT'))
    --popup:AddCheckBox(Locale.Lookup("LOC_REMEMBER_MY_CHOICE"), false, OnRememberChoice);
    popup:AddCustomButton(Locale.Lookup('LOC_MINESWEEPER_REPLAY'), function()
        ExposedMembers.MineSweeper.Replay()
        m_bGameOver = false
    end);
    popup:AddCustomButton(Locale.Lookup('LOC_MINESWEEPER_EXIT_TO_MAIN'), function()
        Events.ExitToMainMenu()
    end);
    popup:Open();
end


function GameWon()
    -- 当游戏不能以原本的形式显示胜利画面时，就暂时用下面这种方式
    local popup = PopupDialogInGame:new("UnitCaptured")
    popup:AddTitle(Locale.Lookup('LOC_MINESWEEPER_WON_TITLE'))
    popup:AddText(Locale.Lookup('LOC_MINESWEEPER_WON_TEXT'))
    --popup:AddCheckBox(Locale.Lookup("LOC_REMEMBER_MY_CHOICE"), false, OnRememberChoice);
    popup:AddCustomButton(Locale.Lookup('LOC_MINESWEEPER_REPLAY'), function()
        ExposedMembers.MineSweeper.Replay()
        m_bGameOver = false
    end);
    popup:AddCustomButton(Locale.Lookup('LOC_MINESWEEPER_EXIT_TO_MAIN'), function()
        Events.ExitToMainMenu()
    end);
    popup:Open();
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
    
    ctrl = ContextPtr:LookUpControl("/InGame/TopPanel")
    Controls.TopBar:ChangeParent(ctrl)
    
    ctrl = ContextPtr:LookUpControl("/InGame/TopPanel")
    Controls.MS_TipsStack:ChangeParent(ctrl)
    Controls.MS_TipsAnimation:ChangeParent(ctrl)
    Controls.MS_TipsAnimation:SetToBeginning()
    Controls.ToggleTipsButton:RegisterCallback(Mouse.eLClick, function()
        if m_bTipShown then
            m_bTipShown = false
            Controls.MS_TipsAnimation:Reverse()
        else
            m_bTipShown = true
            Controls.MS_TipsAnimation:SetToBeginning()
            Controls.MS_TipsAnimation:Play()
        end
    end)

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





-- 响应单位图标旁的按钮
LuaEvents.MineSweeper_MarkPlot.Add(MarkPlot)
LuaEvents.MineSweeper_DigPlot.Add(DigPlot)


-- 提供给 Gameplay 环境使用
if ExposedMembers.MineSweeper == nil then
    ExposedMembers.MineSweeper = {}
end
ExposedMembers.MineSweeper.GameOver = GameOver
ExposedMembers.MineSweeper.GameWon = GameWon
