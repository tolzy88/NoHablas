-------------------------------------------------------------
-- NoHablas - Realm-based Premade Group Finder filter
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
-- 1) Hide Premade Group Finder listings from blocked realms
------------------------------------------------------------
local isRefreshingResults = false

local function FilterSearchResultsByRealm(panel)
    if isRefreshingResults then return end

    local results = panel and panel.results
    if not results then return end

    local filtered = {}

    for _, resultID in ipairs(results) do
        local info = C_LFGList.GetSearchResultInfo(resultID)

        if not (info and info.leaderName and IsBlockedFullName(info.leaderName)) then
            table.insert(filtered, resultID)
        end
    end

    if #filtered ~= #results then
        panel.results = filtered
        panel.totalResults = #filtered

        isRefreshingResults = true
        LFGListSearchPanel_UpdateResults(panel)
        isRefreshingResults = false
    end
end

------------------------------------------------------------
-- 2) Hide applicants from blocked realms
------------------------------------------------------------
local function FilterApplicantsByRealm(applicants)
    if not applicants then return end

    for idx = #applicants, 1, -1 do
        local applicantID = applicants[idx]
        local info = C_LFGList.GetApplicantInfo(applicantID)
        local shouldHide = false
        local filteredName

        if info and info.numMembers and info.numMembers > 0 then
            for memberIdx = 1, info.numMembers do
                local name = C_LFGList.GetApplicantMemberInfo(applicantID, memberIdx)
                if IsBlockedFullName(name) then
                    shouldHide = true
                    filteredName = name
                    break
                end
            end
        end

        if shouldHide then
            table.remove(applicants, idx)
        end
    end
end

hooksecurefunc("LFGListSearchPanel_UpdateResultList", FilterSearchResultsByRealm)
hooksecurefunc("LFGListUtil_SortApplicants", FilterApplicantsByRealm)
print("NoHablas loaded.")
