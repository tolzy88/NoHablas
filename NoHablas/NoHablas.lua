-------------------------------------------------------------
-- NoHablas - Realm-based Premade Group Finder filter
-- By tolzy88
-------------------------------------------------------------

-- Hard block list (from realm list)
local blockedRealms = {
    -- Latin America
    ["Drakkari"]     = true,
    ["Quel'Thalas"]  = true,
    ["Ragnaros"]     = true,

    -- Brazil
    ["Gallywix"]     = true,
    ["Goldrinn"]     = true,
    ["Nemesis"]      = true,
    ["TolBarad"]     = true,
    ["Azralon"]      = true,
}

------------------------------------------------------------
-- Helpers
------------------------------------------------------------
local function IsBlockedFullName(fullName)
    if not fullName then return false end
    local _, realm = strsplit("-", fullName)
    return realm and blockedRealms[realm]
end

------------------------------------------------------------
-- 1) Hide group listings from blocked realms
------------------------------------------------------------
local isRefreshingResults = false
local retryScheduled = false

local function FilterGroupsByRealm(panel)
    if isRefreshingResults then return end

    local results = panel and panel.results
    if not results then return end

    local filtered = {}
    local sawIncompleteData = false

    for _, resultID in ipairs(results) do
        local info = C_LFGList.GetSearchResultInfo(resultID)

        if not info or not info.leaderName then
            sawIncompleteData = true
            table.insert(filtered, resultID)
        elseif not IsBlockedFullName(info.leaderName) then
            table.insert(filtered, resultID)
        end
    end

    if #filtered ~= #results then
        isRefreshingResults = true
        panel.results = filtered
        panel.totalResults = #filtered
        LFGListSearchPanel_UpdateResults(panel)
        isRefreshingResults = false
    end

    if sawIncompleteData and not retryScheduled then
        retryScheduled = true

        C_Timer.After(0.25, function()
            retryScheduled = false

            local panel = LFGListFrame and LFGListFrame.SearchPanel
            if panel then
                FilterGroupsByRealm(panel)
            end
        end)
    end
end

------------------------------------------------------------
-- 2) Hide group applicants from blocked realms
------------------------------------------------------------
local function FilterApplicantsByRealm(applicants)
    if not applicants then return end

    for idx = #applicants, 1, -1 do
        local applicantID = applicants[idx]
        local info = C_LFGList.GetApplicantInfo(applicantID)

        if info and info.numMembers and info.numMembers > 0 then
            for memberIdx = 1, info.numMembers do
                local name = C_LFGList.GetApplicantMemberInfo(applicantID, memberIdx)
                if IsBlockedFullName(name) then
                    table.remove(applicants, idx)
                    break
                end
            end
        end
    end
end

hooksecurefunc("LFGListSearchPanel_UpdateResultList", FilterGroupsByRealm)
hooksecurefunc("LFGListUtil_SortApplicants", FilterApplicantsByRealm)
print("NoHablas loaded.")
