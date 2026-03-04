-------------------------------------------------------------
-- NoHablas - Realm-based Premade Group Finder filter
------------------------------------------------------------

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
--    IMPORTANT: must hook UpdateResultList, not UpdateResults
------------------------------------------------------------
hooksecurefunc("LFGListSearchPanel_UpdateResultList", function(panel)
    local results = panel.results
    if not results then return end

    local filtered = {}

    for _, resultID in ipairs(results) do
        local info = C_LFGList.GetSearchResultInfo(resultID)

        if info and info.leaderName then
            if not IsBlockedFullName(info.leaderName) then
                table.insert(filtered, resultID)
            end
        else
            -- Fail-open: keep entries we can't safely inspect
            table.insert(filtered, resultID)
        end
    end

    panel.results = filtered
    panel.totalResults = #filtered
end)

------------------------------------------------------------
-- 2) Auto-decline applicants from blocked realms
------------------------------------------------------------
local f = CreateFrame("Frame")
f:RegisterEvent("LFG_LIST_APPLICANT_UPDATED")
f:RegisterEvent("LFG_LIST_APPLICANT_LIST_UPDATED")

f:SetScript("OnEvent", function()
    local applicants = C_LFGList.GetApplicants()
    if not applicants then return end

    for _, applicantID in ipairs(applicants) do
        local info = C_LFGList.GetApplicantInfo(applicantID)
        if info and info.applicationStatus == "applied" then
            for _, member in ipairs(info.members or {}) do
                if IsBlockedFullName(member.name) then
                    C_LFGList.DeclineApplicant(applicantID)
                    break
                end
            end
        end
    end
end)

print("NoHablas loaded.")