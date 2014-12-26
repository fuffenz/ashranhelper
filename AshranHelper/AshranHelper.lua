--
--  AshranHelper 
--

local myFrame=CreateFrame("Frame")
local keywords={"inv","invite"}
local updateTimer = 0
local playCounter = 0

function eventHandler(self,e,...) 
	local arg1 = ...

	if (e == "ADDON_LOADED" and arg1 == "AshranHelper") then
		if AshranHelperInviteEnabled == nil then
			AshranHelperInviteEnabled = false;
		end
	end

	-- print auto-invite status when we enter Ashran
	if (e == "ZONE_CHANGED_NEW_AREA" and GetRealZoneText() == "Ashran") then
		if AshranHelperInviteEnabled then
			print("Ashran auto-invite is active")
		else
			print("Ashran auto-invite is not active (do /ashranhelper auto to activate)")
		end
	end

	if (AshranHelperInviteEnabled and e == "CHAT_MSG_CHANNEL" or e == "CHAT_MSG_WHISPER" or e == "CHAT_MSG_SAY") then
		local message,sender,_,_,_,_,_,_,chName,_,_,id = ...
		-- look for messages in General - Ashran, but only if in raid and we have free spots
		if IsInRaid() and (GetNumGroupMembers() < 40) and chName:lower():find("ashran") then
			local firstWord = message:match("(%S+).*")
			if(firstWord ~= nil) then
				for _,t in ipairs(keywords) 
				do 
					if (t == firstWord:lower()) then 	
						-- invite will fail if we're not leader/assist, doesn't really matter...					
						InviteUnit(sender) 
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
	if (msg:find("Broken Bones")) then
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
			-- are there localized zone names?  no idea...
			if(zone == "Ashran") then
			   	if(queueStatus == "confirm") then
			   		if(playCounter == 0) then 
						PlaySoundFile("sound\\interface\\levelup2.ogg")
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

