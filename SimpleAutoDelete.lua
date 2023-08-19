--[[

	SimpleAutoDelete
		Automatically delete items specified in the list.
		Will only trigger outside of combat.

		By null
		https://github.com/nullfoxh/SimpleAutoDelete-WOTLK

]]--

---------------------------------------------------------------------------------------------

local GetContainerNumSlots, GetContainerNumFreeSlots, UnitAffectingCombat, GetItemInfo
	= GetContainerNumSlots, GetContainerNumFreeSlots, UnitAffectingCombat, GetItemInfo

local print = function(msg)
	DEFAULT_CHAT_FRAME:AddMessage("|cffa0f6aaSimpleAutoDelete|r: "..msg)
end

local printv = function(msg)
	if SimpleAutoDelete.verbose then print(msg) end
end

SimpleAutoDelete = {
	list = {},
	verbose = true,
	delay = 0.4
}

---------------------------------------------------------------------------------------------

local function getTableSize(t)
	local count = 0
	for _ in pairs(t) do
		count = count + 1
	end
	return count
end

local function matchItem(arg)
	local itemName, itemLink = GetItemInfo(arg)

	if not itemName then
		itemName = arg
		itemLink = arg
	end

	return itemName, itemLink
end

local function getItemNameById(id)
	local itemName = GetItemInfo(id)
	return itemName
end

---------------------------------------------------------------------------------------------

local function deleteItems(test)
	local numDeleted = 0
	if test then
		print("Running test, looking for items to delete.")
	end

	for bag = 0, NUM_BAG_SLOTS do
		for slot = 1, GetContainerNumSlots(bag) do
			local itemId = GetContainerItemID(bag, slot)

			if itemId then
				local itemName = getItemNameById(itemId)

				if itemName then
					for i, item in ipairs(SimpleAutoDelete.list) do
						if itemName == item then
							local _, itemLink = matchItem(itemId)

							if test then
								print("Found item that would be deleted ".. itemLink..".")
							else
								printv("Deleting item ".. itemLink..".")
								PickupContainerItem(bag, slot)
								DeleteCursorItem()
							end

							numDeleted = numDeleted + 1
						end
					end
				end
			end
		end
	end

	if test then
		print("Found "..numDeleted.." items to delete.")
	end
end

local throttle = 0
local f = CreateFrame("Frame")
f:Hide()

f:SetScript("OnEvent", function(self, event, ...)
	if event == "LOOT_CLOSED" then
		if not UnitAffectingCombat("player") then
			f:Show()
		else
			f:RegisterEvent("PLAYER_REGEN_ENABLED")
		end
	elseif event == "PLAYER_REGEN_ENABLED" then
		f:Show()
		f:UnregisterEvent("PLAYER_REGEN_ENABLED")
	end
end)

f:SetScript("OnUpdate", function(self, elapsed)
	throttle = throttle + elapsed

	if throttle > SimpleAutoDelete.delay then
		throttle = 0
		deleteItems()
		self:Hide()
	end
end)

f:RegisterEvent("LOOT_CLOSED")

---------------------------------------------------------------------------------------------

local function addItem(arg)
	local itemName, itemLink = matchItem(arg)

	for _, item in ipairs(SimpleAutoDelete.list) do
		if item == itemName then
			print(itemLink .. " already exists in the list.")
			return
		end
	end

	print(itemLink .. " added to the list.")
	table.insert(SimpleAutoDelete.list, itemName)
end

local function removeItem(arg)
	local itemName, itemLink = matchItem(arg)

	for i, item in ipairs(SimpleAutoDelete.list) do
		if item == itemName then
			table.remove(SimpleAutoDelete.list, i)
			print(itemLink .. " removed from the list.")
			return
		end
	end

	print(itemLink .. " was not found in the list.")
end

local function viewItems()
	if getTableSize(SimpleAutoDelete.list) == 0 then
		print("The list of items to be deleted is currently empty.")
		return
	end

	print("Items in list:")
	for _, item in ipairs(SimpleAutoDelete.list) do
		local itemName, itemLink = matchItem(item)
		print("  " .. itemLink)
	end
end

local function setDelay(arg)
	local num = tonumber(arg)

	if num then
		SimpleAutoDelete.delay = num
		print("Delay set to " .. SimpleAutoDelete.delay .. " seconds.")
	else
		print("Invalid argument for delay. Please specify a number in seconds. Delay is currently set to ".. SimpleAutoDelete.delay .. " seconds.")
	end
end

local function setPrint(arg)
	if arg == "true" then
		SimpleAutoDelete.print = true
	elseif arg == "false" then
		SimpleAutoDelete.print = false
	else
		SimpleAutoDelete.print = not SimpleAutoDelete.print
	end

	if SimpleAutoDelete.print then
		print("Printing enabled.")
	else
		print("Printing disabled.")
	end
end

SLASH_SIMPLEAUTODELETE1 = "/simpleautodelete"
SLASH_SIMPLEAUTODELETE2 = "/sad"
SlashCmdList["SIMPLEAUTODELETE"] = function(cmd)
	local _, _, cmd, arg = string.find(cmd, "%s?(%w+)%s?(.*)")
	if cmd == "add" then
		addItem(arg)
	elseif cmd == "remove" then
		removeItem(arg)
	elseif cmd == "list" then
		viewItems()
	elseif cmd == "delay" then
		setDelay(arg)
	elseif cmd == "print" then
		setPrint(arg)
	elseif cmd == "test" then
		deleteItems(true)
	elseif cmd == "run" then
		deleteItems()
	else
		print("Unrecognized command. The available are commands:")
		print("/sad add <item name or link> - Adds an item to the list")
		print("/sad remove <item name or link> - Removes an item from the list")
		print("/sad list - Lists all items in the list")
		print("/sad delay <seconds> - Sets the delay time in seconds for deletion")
		print("/sad print <true/false> - Toggles printing of items being deleted")
		print("/sad test - Lists all items in your bags that would be deleted")
		print("/sad run - Scan your bags now and look for items to delete")
	end
end