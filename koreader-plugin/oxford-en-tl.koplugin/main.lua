local json = require("json")
local socket_url = require("socket.url")
local http = require("socket.http")
local https_ok, https = pcall(require, "ssl.https")
local ltn12 = require("ltn12")
local UIManager = require("ui/uimanager")
local InfoMessage = require("ui/widget/infomessage")
local ConfirmBox = require("ui/widget/confirmbox")
local _ = require("gettext")
local DataStorage = require("datastorage")
local lfs = require("-lfs")
local Plugin = require("plugin")

local OxfordUpdater = Plugin:extend{
    name = "oxford-en-tl",
}

local API = "https://api.github.com/repos/mrcloudworks-glitch/oxford-english-to-tagalog/contents/oxford-en-tl?ref=main"
local RAW = "https://raw.githubusercontent.com/mrcloudworks-glitch/oxford-english-to-tagalog/main/oxford-en-tl/"
local STEM = "oxford-en-tl"
local REQUIRED = { STEM .. ".dict.dz", STEM .. ".idx", STEM .. ".ifo", STEM .. ".syn" }

local function request(url, sink)
    local client = url:match("^https:") and https_ok and https or http
    if url:match("^https:") and not https_ok then
        return nil, "HTTPS support is unavailable in this KOReader build"
    end
    local ok, code, headers, status = client.request{
        url = url,
        method = "GET",
        headers = { ["User-Agent"] = "KOReader-Oxford-Tagalog-Updater", ["Accept"] = "application/vnd.github+json" },
        sink = sink,
        redirect = true,
    }
    if not ok or tonumber(code) ~= 200 then
        return nil, status or ("HTTP " .. tostring(code))
    end
    return true, headers
end

local function read_remote_manifest()
    local chunks = {}
    local ok, err = request(RAW .. "update.json", ltn12.sink.table(chunks))
    if not ok then return nil, err end
    local good, result = pcall(json.decode, table.concat(chunks))
    if not good or type(result) ~= "table" or type(result.files) ~= "table" then
        return nil, "The repository returned an invalid update manifest"
    end
    return result
end

local function mkdir(path)
    local current = ""
    for part in path:gmatch("[^/]+") do
        current = current == "" and (path:sub(1, 1) == "/" and "/" .. part or part) or current .. "/" .. part
        if not lfs.attributes(current) then
            local ok, err = lfs.mkdir(current)
            if not ok then return nil, err end
        end
    end
    return true
end

local function destination()
    local root = DataStorage:getDataDir() .. "/dict"
    local path = root .. "/" .. STEM
    local ok, err = mkdir(path)
    if not ok then return nil, err end
    return path
end

local function download_update()
    local manifest, err = read_remote_manifest()
    if not manifest then return nil, err end
    local target, direrr = destination()
    if not target then return nil, direrr end

    local staged = {}
    -- Stage every required file before replacing any installed file.
    for _, filename in ipairs(REQUIRED) do
        local meta = manifest.files[filename]
        if type(meta) ~= "table" or type(meta.size) ~= "number" then
            for _, p in ipairs(staged) do os.remove(p) end
            return nil, "Update manifest is missing " .. filename
        end
        local temp = target .. "/." .. filename .. ".download"
        local file, ferr = io.open(temp, "wb")
        if not file then return nil, ferr end
        local ok, rerr = request(RAW .. socket_url.escape(filename), ltn12.sink.file(file))
        local attr = lfs.attributes(temp)
        if not ok or not attr or attr.size ~= meta.size then
            os.remove(temp)
            for _, p in ipairs(staged) do os.remove(p) end
            return nil, rerr or (filename .. " size did not match the published manifest")
        end
        staged[#staged + 1] = temp
    end

    for i, filename in ipairs(REQUIRED) do
        local final = target .. "/" .. filename
        os.remove(final .. ".previous")
        if lfs.attributes(final) then os.rename(final, final .. ".previous") end
        local ok, rerr = os.rename(staged[i], final)
        if not ok then
            for _, f in ipairs(REQUIRED) do
                local backup = target .. "/" .. f .. ".previous"
                if lfs.attributes(backup) then os.remove(target .. "/" .. f); os.rename(backup, target .. "/" .. f) end
            end
            for _, p in ipairs(staged) do os.remove(p) end
            return nil, rerr or ("Could not install " .. filename)
        end
    end
    for _, filename in ipairs(REQUIRED) do os.remove(target .. "/" .. filename .. ".previous") end
    local mf = io.open(target .. "/update.json", "wb")
    if mf then mf:write(json.encode(manifest)); mf:close() end
    return manifest
end

function OxfordUpdater:init()
    self.ui.menu:registerToMainMenu(self)
end

function OxfordUpdater:addToMainMenu(menu_items)
    menu_items.oxford_tagalog_update = {
        text = _("Update Oxford English-Tagalog dictionary"),
        sorting = " tools ",
        callback = function()
            UIManager:show(ConfirmBox:new{
                text = _("Check GitHub and download the latest Oxford English-Tagalog dictionary? Wi-Fi is required. The dictionary is installed in KOReader's data/dict folder."),
                ok_text = _("Update"),
                ok_callback = function()
                    UIManager:show(InfoMessage:new{ text = _("Checking for updates…") })
                    local result, err = download_update()
                    if result then
                        UIManager:show(InfoMessage:new{ text = string.format(_("Dictionary updated: %d headwords."), tonumber(result.headwords) or 0) })
                    else
                        UIManager:show(InfoMessage:new{ text = _("Update failed: ") .. tostring(err) })
                    end
                end,
            })
        end,
    }
end

return OxfordUpdater
