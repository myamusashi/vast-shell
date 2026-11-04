pragma ComponentBehavior: Bound
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

import qs.Core.Utils
import qs.Services

Singleton {
    id: root

    // lua-cjson availability inside Hyprland's embedded Lua: "unknown" | "checking" | "installed" | "missing"
    readonly property string cjsonCheckFile: `${Paths.cacheDir}/vast-shell-cjson-check`
    readonly property string cjsonEvalChunk: `local file = io.open("${Paths.cacheDir}/vast-shell-cjson-check", "w"); if file then file:write(tostring(select(1, pcall(require, "cjson")))); file:close() end`
    readonly property string hyprConfigDir: `${Paths.configDir}/hypr`
    readonly property string luaHeader: `-- Created once by vast-shell; yours to edit. Reads ~/.config/vast-shell/*.json.
-- Adjust it if your lua-cjson lives elsewhere.
package.cpath = os.getenv("HOME") .. "/.config/hypr/?.so;" .. package.cpath
local ok, cjson = pcall(require, "cjson")`
    readonly property string luaHelpers: `local configDirectory = os.getenv("HOME") .. "/.config/vast-shell/"

-- lua-cjson decodes every JSON number as a float; integer-typed fields reject those.
local function normalizeNumbers(value)
    if type(value) == "table" then
        for key, item in pairs(value) do
            value[key] = normalizeNumbers(item)
        end
        return value
    end
    if type(value) == "number" then
        return math.tointeger(value) or value
    end
    return value
end

local function readJson(fileName)
    local file, openError = io.open(configDirectory .. fileName, "r")
    if not file then
        return nil, openError
    end
    local content = file:read("*a")
    file:close()
    local decodedOk, decoded = pcall(cjson.decode, content)
    if not decodedOk then
        return nil, tostring(decoded)
    end
    if type(decoded) ~= "table" then
        return nil, "expected JSON object"
    end
    return normalizeNumbers(decoded), nil
end

local function isNull(value)
    return value == nil or value == cjson.null
end`
    readonly property string luaTemplate: `${luaHeader}
if not ok or not hl or not hl.monitor or not hl.config or not hl.on then
    return
end

${luaHelpers}

local function applyMonitors()
    local monitorData = readJson("monitor.json")
    if monitorData and type(monitorData.monitors) == "table" then
        for description, monitor in pairs(monitorData.monitors) do
            if type(monitor) == "table" and not isNull(monitor.disabled) and monitor.disabled then
                pcall(hl.monitor, { output = "desc:" .. description, disabled = true })
            else
                local rule = { output = "desc:" .. description }
                if not isNull(monitor.width) and not isNull(monitor.height) and not isNull(monitor.refreshRate) then
                    rule.mode = string.format("%dx%d@%.2f", monitor.width, monitor.height, monitor.refreshRate)
                end
                if not isNull(monitor.x) and not isNull(monitor.y) then
                    rule.position = string.format("%dx%d", monitor.x, monitor.y)
                end
                if not isNull(monitor.scale) then rule.scale = monitor.scale end
                if not isNull(monitor.transform) then rule.transform = monitor.transform end
                if not isNull(monitor.bitdepth) then rule.bitdepth = monitor.bitdepth end
                if not isNull(monitor.cm) then rule.cm = monitor.cm end
                if not isNull(monitor.sdrbrightness) then rule.sdrbrightness = monitor.sdrbrightness end
                if not isNull(monitor.sdrsaturation) then rule.sdrsaturation = monitor.sdrsaturation end
                if not isNull(monitor.icc) and monitor.icc ~= "" then rule.icc = monitor.icc end
                pcall(hl.monitor, rule)
            end
        end
    end
end

local function applyGenerals()
    local generalData = readJson("generals.json")
    if generalData and type(generalData.generals) == "table" and next(generalData.generals) ~= nil then
        pcall(hl.config, generalData.generals)
    end
end

applyMonitors()
applyGenerals()

hl.on("monitor.added", applyMonitors)
hl.on("monitor.removed", applyMonitors)`
    readonly property bool   onHyprland: Hyprland.usingLua
    readonly property string requireLine: "require(\"vast_shell\")"
    readonly property string rulesErrorsFile: `${Paths.cacheDir}/vast-shell-rules-errors`
    readonly property string rulesLuaPath: `${hyprConfigDir}/vast_shell_rules.lua`
    readonly property string rulesLuaTemplate: `${luaHeader}
local errorFilePath = "${rulesErrorsFile}"

local function writeErrors(messages)
    local file = io.open(errorFilePath, "w")
    if not file then
        return
    end
    if #messages > 0 then
        file:write(table.concat(messages, "\\n"))
    end
    file:close()
end

if not ok then
    writeErrors({ "lua-cjson is not available: " .. tostring(cjson) })
    return
end
if not hl or not hl.window_rule or not hl.layer_rule then
    writeErrors({ "Hyprland Lua rule API (hl.window_rule / hl.layer_rule) is not available" })
    return
end

${root.luaHelpers}

local errors = {}

local function fillTable(target, source)
    for key, value in pairs(source or {}) do
        if not isNull(value) then
            target[key] = value
        end
    end
    return target
end

local function buildRule(entry)
    if type(entry) ~= "table" then
        return nil
    end
    local rule = {}
    if type(entry.name) == "string" and entry.name ~= "" then
        rule.name = entry.name
    end
    if entry.enabled == false then
        rule.enabled = false
    end
    rule.match = fillTable({}, entry.match)
    if next(rule.match) == nil then
        return nil
    end
    fillTable(rule, entry.effects)
    return rule
end

local function applyRules(fileName, registerRule)
    local data, readError = readJson(fileName)
    if not data then
        if readError and not tostring(readError):find("No such file or directory", 1, true) then
            table.insert(errors, fileName .. ": " .. tostring(readError))
        end
        return
    end
    if type(data.rules) ~= "table" then
        table.insert(errors, fileName .. ": missing rules array")
        return
    end
    for index, entry in ipairs(data.rules) do
        local rule = buildRule(entry)
        if rule then
            local registeredOk, registerError = pcall(registerRule, rule)
            if not registeredOk then
                local label = (type(entry.name) == "string" and entry.name ~= "") and entry.name or ("#" .. tostring(index))
                table.insert(errors, fileName .. " (" .. label .. "): " .. tostring(registerError))
            end
        end
    end
end

applyRules("windowrules.json", hl.window_rule)
applyRules("layerrules.json", hl.layer_rule)
writeErrors(errors)`
    readonly property string rulesRequireLine: "require(\"vast_shell_rules\")"
    readonly property string vastShellLuaPath: `${hyprConfigDir}/vast_shell.lua`

    property string          cjsonState: "unknown"
    // vast_shell.lua lifecycle: "unknown" | "missing" | "creating" | "exists" | "created"
    property alias           luaFileState: luaBootstrap.fileState
    property bool            reloadPending: false
    // vast_shell_rules.lua lifecycle: "unknown" | "missing" | "creating" | "exists" | "created"
    property alias           rulesLuaFileState: rulesLuaBootstrap.fileState

    function                 checkCjson(): void {
        if (!onHyprland || cjsonState === "checking")
            return;
        cjsonState         = "checking";
        cjsonCheck.running = true;
    }

    function                 copyRequireLine(): void {
        luaBootstrap.copyRequireLine();
    }

    function                 copyRulesRequireLine(): void {
        rulesLuaBootstrap.copyRequireLine();
    }

    function                 ensureLuaFile(): void {
        luaBootstrap.ensureFile();
    }

    function                 ensureRulesLuaFile(): void {
        rulesLuaBootstrap.ensureFile();
    }

    function                 reloadHyprland(): void {
        reloadDebounceTimer.restart();
    }

    onOnHyprlandChanged: {
        if (onHyprland && cjsonState === "unknown")
            checkCjson();
    }

    LuaBootstrapFile {
        id: luaBootstrap

        createFailedMessage: qsTr("Failed to create vast_shell.lua")
        filePath: root.vastShellLuaPath
        requireLine: root.requireLine
        templateContent: root.luaTemplate
    }

    LuaBootstrapFile {
        id: rulesLuaBootstrap

        createFailedMessage: qsTr("Failed to create vast_shell_rules.lua")
        filePath: root.rulesLuaPath
        requireLine: root.rulesRequireLine
        templateContent: root.rulesLuaTemplate
    }

    Process {
        id: cjsonCheck

        command: ["hyprctl", "eval", root.cjsonEvalChunk]
        stdout: StdioCollector {
            id: cjsonStdout
        }
        onExited: {
            if (cjsonStdout.text.trim() === "ok")
                cjsonResult.reload();
            else
                root.cjsonState = "unknown";
        }
    }

    FileView {
        id: cjsonResult

        path: root.cjsonCheckFile
        watchChanges: false
        onLoaded: {
            const result    = text().trim();
            root.cjsonState = result === "true" ? "installed" : (result === "false" ? "missing" : "unknown");
        }
        onLoadFailed: root.cjsonState = "unknown"
    }

    FileView {
        id: rulesErrorsView

        path: root.rulesErrorsFile
        preload: false
        printErrors: false
        watchChanges: false
        onLoaded: {
            const message = text().trim();
            if (message !== "")
                ToastService.show(message, qsTr("Hyprland"), "warning", 5000);
        }
    }

    Process {
        id: hyprctlReload

        command: ["hyprctl", "reload"]
        onExited: {
            if (root.reloadPending) {
                root.reloadPending    = false;
                hyprctlReload.running = true;
                return;
            }
            rulesErrorsView.reload();
        }
    }

    Timer {
        id: reloadDebounceTimer

        interval: 500
        onTriggered: {
            if (hyprctlReload.running)
                root.reloadPending = true;
            else
                hyprctlReload.running = true;
        }
    }

    component LuaBootstrapFile: Scope {
        id: bootstrap

        required property string createFailedMessage
        required property string filePath
        required property string requireLine
        required property string templateContent

        property string          fileState: "unknown"

        function                 copyRequireLine(): void {
            requireCopyProcess.running = true;
        }

        function                 ensureFile(): void {
            if (bootstrap.fileState !== "missing")
                return;
            bootstrap.fileState = "creating";
            targetFile.setText(bootstrap.templateContent);
        }

        FileView {
            id: targetFile

            path: bootstrap.filePath
            watchChanges: false
            onLoaded: bootstrap.fileState = "exists"
            onLoadFailed: errorCode => {
                if (errorCode === FileViewError.FileNotFound) {
                    bootstrap.fileState = "missing";
                    bootstrap.ensureFile();
                } else {
                    bootstrap.fileState = "unknown";
                }
            }
            onSaved: {
                if (bootstrap.fileState === "creating")
                    bootstrap.fileState = "created";
            }
            onSaveFailed: {
                if (bootstrap.fileState === "creating") {
                    bootstrap.fileState = "missing";
                    ToastService.show(bootstrap.createFailedMessage, qsTr("Hyprland"), "warning", 3000);
                }
            }
        }

        Process {
            id: requireCopyProcess

            command: ["wl-copy", "--", bootstrap.requireLine]
        }
    }
}
