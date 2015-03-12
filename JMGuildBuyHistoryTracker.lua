
---
--- JMGuildBuyHistoryTracker
---

--[[

    Variable declaration

 ]]

---
-- @field name
-- @field savedVariablesName
--
local Config = {
    name = 'JMGuildBuyHistoryTracker',
    savedVariablesName = 'JMGuildBuyHistoryTrackerSavedVariables',
}

local SavedVariables = {}
local BuyList = {}
local pendingBuy = {}

--[[

    Collector

 ]]

local Collector = {}

function Collector:getPendingPurchageItemInformation(slotIndex)
    local icon, itemName, quality, stackCount, sellerName, timeRemaining, purchasePrice, currencyType = GetTradingHouseSearchResultItemInfo(slotIndex)
    local itemLink = GetTradingHouseSearchResultItemLink(slotIndex)
    local _, _, _, itemId, _ = ZO_LinkHandler_ParseLink(itemLink)

    local selectedGuildId = GetSelectedTradingHouseGuildId()
    local selectedGuildName
    for guildIndex = 0, GetNumTradingHouseGuilds() do
        local guildId, guildName, guildAlliance = GetTradingHouseGuildDetails(guildIndex)
        if guildId == selectedGuildId then
            selectedGuildName = guildName
        end
    end

    if not selectedGuildName then
        d('Could not find a guild name')
        selectedGuildName = ''
    end

    pendingBuy = {
        seller = sellerName,
        quantity = stackCount,
        itemLink = itemLink,
        price = purchasePrice,
        itemId = itemId,
        guildName = selectedGuildName
    }
end

function Collector:itemBought(price)
    if pendingBuy == {} then
        d('I have nothing pending to buy')
        return
    end

    table.insert(BuyList, {
        seller = pendingBuy.seller,
        quantity = pendingBuy.quantity,
        itemLink = pendingBuy.itemLink,
        price = pendingBuy.price,
        itemId = pendingBuy.itemId,
        guildName = pendingBuy.guildName,
        saleTimestamp = GetTimeStamp(),
    })

    pendingBuy = {}
end

--[[

    Initialize

 ]]

---
-- Start of the addon
--
local function Initialize()
    -- Load the saved variables
    SavedVariables = ZO_SavedVars:NewAccountWide(Config.savedVariablesName, 1, nil, {
        buyList = {},
    })
    BuyList = SavedVariables.buyList

    EVENT_MANAGER:RegisterForEvent(
        Config.name,
        EVENT_TRADING_HOUSE_CONFIRM_ITEM_PURCHASE,
        function (_, slotIndex)
            Collector:getPendingPurchageItemInformation(slotIndex)
        end
    )

    EVENT_MANAGER:RegisterForEvent(
        Config.name,
        EVENT_MONEY_UPDATE,
        function (eventCode, newMoney, oldMoney, reason)
            if reason == 31 then
                Collector:itemBought(oldMoney - newMoney)
            end
        end
    )
end


--[[

    Api

 ]]

---
-- Making some functions public
--
-- @field scan
--
JMGuildBuyHistoryTracker = {

    ---
    -- Get all my buys
    --
    getAll = function()
        return ZO_DeepTableCopy(BuyList)
    end,
}

--[[

    Events

 ]]

--- Adding the initialize handler
EVENT_MANAGER:RegisterForEvent(
    Config.name,
    EVENT_ADD_ON_LOADED,
    function (event, addonName)
        if addonName ~= Config.name then
            return
        end

        Initialize()
        EVENT_MANAGER:UnregisterForEvent(Config.name, EVENT_ADD_ON_LOADED)
    end
)
