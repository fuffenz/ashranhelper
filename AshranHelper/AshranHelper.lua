--
--  AshranHelper 
--  
--

local myFrame=CreateFrame("Frame")
-- need to localize keywords...
local keywords={"inv","invite"}
local updateTimer = 0
local playCounter = 0
local ashranAreaID = 978;
-- simple way to localize names for non-English clients
local i18nAshran = GetMapNameByID(ashranAreaID):lower() -- "ashran";
local i18nBrokenBones = GetItemInfo(118043) -- "Broken Bones"
local isInAshran = false;

function eventHandler(self,e,...) 
	local arg1 = ...

	if (e == "ADDON_LOADED" and arg1 == "AshranHelper") then
		if AshranHelperInviteEnabled == nil then
			AshranHelperInviteEnabled = false;
		end
		if AshranHelperInvites == nil or AshranHelperBones == nil then
			AshranHelperInvites = 0
			AshranHelperBones = 0
		end
	end

	if (e == "ZONE_CHANGED_NEW_AREA") then
		SetMapToCurrentZone()
		areaid = GetCurrentMapAreaID()

		if(areaid == ashranAreaID) then
			isInAshran = true;
			-- print auto-invite status when we enter Ashran
			if AshranHelperInviteEnabled then
				print("Ashran auto-invite is active and will invite when you are in a raid group")
			else
				print("Ashran auto-invite is not active (do /ashranhelper auto to activate)")
			end
		else
			if(isInAshran) then
				if(AshranHelperInviteEnabled) then
					print("You have left Ashran and auto-invite is no longer active")
				end
				isInAshran = false
			end
		end
	end

	if (AshranHelperInviteEnabled and e == "CHAT_MSG_CHANNEL" or e == "CHAT_MSG_WHISPER" or e == "CHAT_MSG_SAY") then
		local message,sender,_,_,_,_,_,_,chName,_,_,id = ...
		-- look for messages in General - Ashran, but only if in raid and we have free spots
		if IsInRaid() and (GetNumGroupMembers() < 40) and chName:lower():find(i18nAshran) then
			local firstWord = message:match("(%S+).*")
			if(firstWord ~= nil) then
				for _,t in ipairs(keywords) 
				do 
					if (t == firstWord:lower()) then 	
						-- invite will fail if we're not leader/assist, doesn't really matter...					
						InviteUnit(sender) 
						AshranHelperInvites = AshranHelperInvites + 1
						break 
					end 
				end 
			end
		end
	end
end

-- 
--  Filter out the spammy Broken Bones loot messages
--
function lootFilter(self, event, msg) 
	if (msg ~= nil and msg:find(i18nBrokenBones)) then
		AshranHelperBones = AshranHelperBones + 1
		return true
	end
	return false
end

-- 
-- ugly but working way to detect ashran queue, play a sound when ready to enter
--
function uiUpdate(self, elapsed) 
	updateTimer = updateTimer + elapsed
	if(updateTimer > 2) then
		for i=1, MAX_WORLD_PVP_QUEUES do
		    local queueStatus, zone = GetWorldPVPQueueStatus(i)   
			
			if(zone ~= nil and zone:lower() == i18nAshran) then
			   	if(queueStatus == "confirm") then
			   		if(playCounter == 0) then 
						PlaySoundFile("sound\\interface\\levelup2.ogg", "Master")
					end
					playCounter = playCounter + 1
				else
					playCounter = 0
			   end
			end
		end

		updateTimer = 0
	end
end

--
-- print auto-invite status
--
function inviteStatus()
	print("|cFF00FF00AshranHelper|r")
	if AshranHelperInviteEnabled then 
		print("Ashran auto-invite is Enabled") 
	else 
		print("Ashran auto-invite is Disabled") 
	end 
end

--
-- basic slash command 
--
function slashCommand(arg)
	if arg == "auto" then
		AshranHelperInviteEnabled = not AshranHelperInviteEnabled 
		inviteStatus()
	else
		inviteStatus()
		print("So far, " .. AshranHelperBones .. " bone spam suppressed and " .. AshranHelperInvites .. " invites sent")
		print "To enable or disable auto-invite, use:"
		print "/ashranhelper auto"
	end
end

myFrame:SetScript("OnEvent",eventHandler);
myFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA") 	
myFrame:RegisterEvent("CHAT_MSG_CHANNEL") 		
myFrame:RegisterEvent("CHAT_MSG_WHISPER") 
myFrame:RegisterEvent("CHAT_MSG_SAY") 
ChatFrame_AddMessageEventFilter("CHAT_MSG_LOOT", lootFilter)
myFrame:SetScript("OnUpdate", uiUpdate)
myFrame:RegisterEvent("ADDON_LOADED")

SlashCmdList.ASHRANAUTO = slashCommand
SLASH_ASHRANAUTO1 = "/ashranhelper"

