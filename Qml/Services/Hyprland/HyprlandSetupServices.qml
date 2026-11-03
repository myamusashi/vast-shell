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
    readonly property bool   onHyprland: Hyprland.usingLua
    readonly property string requireLine: "require(\"vast_shell\")"
    readonly property string rulesLuaPath: `${hyprConfigDir}/vast_shell_rules.lua`
    readonly property string rulesRequireLine: "require(\"vast_shell_rules\")"
    readonly property string vastShellLuaPath: `${hyprConfigDir}/vast_shell.lua`

    property string          cjsonState: "unknown"
    // vast_shell.lua lifecycle: "unknown" | "missing" | "creating" | "exists" | "created"
    property string          luaFileState: "unknown"
    // vast_shell_rules.lua lifecycle: "unknown" | "missing" | "creating" | "exists" | "created"
    readonly property string luaTemplate: `
        -- Created once by vast-shell; yours to edit. Reads ~/.config/vast-shell/*.json.
        -- Adjust it if your lua-cjson lives elsewhere.
        package.cpath = os.getenv("HOME") .. "/.config/hypr/?.so;" .. package.cpath
        local ok, cjson = pcall(require, "cjson")
        if not ok or not hl or not hl.monitor or not hl.config or not hl.on then
            return
        end

        local configDirectory = os.getenv("HOME") .. "/.config/vast-shell/"

        -- lua-cjson decodes every JSON number as a float; integer-typed options reject those.
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
            local file = io.open(configDirectory .. fileName, "r")
            if not file then
                return nil
            end
            local content = file:read("*a")
            file:close()
            local decodedOk, decoded = pcall(cjson.decode, content)
            if not decodedOk or type(decoded) ~= "table" then
                return nil
            end
            return normalizeNumbers(decoded)
        end

        local function isNull(value)
            return value == nil or value == cjson.null
        end

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

        -- Other monitor automations may register rules on monitor events after this
        -- file runs; re-asserting here keeps the stored layout winning (this listener
        -- runs last because this file is required at the bottom of hyprland.lua).
        hl.on("monitor.added", applyMonitors)
        hl.on("monitor.removed", applyMonitors)
    `
    readonly property string rulesLuaTemplate: `
        -- Created once by vast-shell; yours to edit. Reads ~/.config/vast-shell/*.json.
        -- Adjust it if your lua-cjson lives elsewhere.
        package.cpath = os.getenv("HOME") .. "/.config/hypr/?.so;" .. package.cpath
        local ok, cjson = pcall(require, "cjson")
        if not ok or not hl or not hl.window_rule or not hl.layer_rule then
            return
        end

        local configDirectory = os.getenv("HOME") .. "/.config/vast-shell/"

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
            local file = io.open(configDirectory .. fileName, "r")
            if not file then
                return nil
            end
            local content = file:read("*a")
            file:close()
            local decodedOk, decoded = pcall(cjson.decode, content)
            if not decodedOk or type(decoded) ~= "table" then
                return nil
            end
            return normalizeNumbers(decoded)
        end

        local function isNull(value)
            return value == nil or value == cjson.null
        end

        -- Copies entries into the rule, skipping nulls so an omitted or null field
        -- never reaches Hyprland. JSON false is kept: effects like float = false
        -- and decorate = false are meaningful.
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
            -- Hyprland ignores rules without match properties, so skip them outright.
            if next(rule.match) == nil then
                return nil
            end
            fillTable(rule, entry.effects)
            return rule
        end

        local function applyRules(fileName, registerRule)
            local data = readJson(fileName)
            if not data or type(data.rules) ~= "table" then
                return
            end
            -- ipairs keeps the JSON array order; effects are applied top to bottom
            -- and the last matching rule wins.
            for _, entry in ipairs(data.rules) do
                local rule = buildRule(entry)
                if rule then
                    pcall(registerRule, rule)
                end
            end
        end

        applyRules("windowrules.json", hl.window_rule)
        applyRules("layerrules.json", hl.layer_rule)
    `

    property string          rulesLuaFileState: "unknown"

    function                 checkCjson(): void {
        if (!onHyprland || cjsonState === "checking")
            return;
        cjsonState         = "checking";
        cjsonCheck.running = true;
    }

    function                 copyRequireLine(): void {
        requireCopy.running = true;
    }

    function                 copyRulesRequireLine(): void {
        requireRulesCopy.running = true;
    }

    function                 ensureLuaFile(): void {
        if (luaFileState !== "missing")
            return;
        luaFileState = "creating";
        luaFile.setText(luaTemplate);
    }

    function                 ensureRulesLuaFile(): void {
        if (rulesLuaFileState !== "missing")
            return;
        rulesLuaFileState = "creating";
        rulesLuaFile.setText(rulesLuaTemplate);
    }

    function                 reloadHyprland(): void {
        hyprctlReload.running = true;
    }

    onOnHyprlandChanged: {
        if (onHyprland && cjsonState === "unknown")
            checkCjson();
    }

    FileView {
        id: luaFile

        path: root.vastShellLuaPath
        watchChanges: false
        onLoaded: root.luaFileState = "exists"
        onLoadFailed: err => {
            if (err === FileViewError.FileNotFound) {
                root.luaFileState = "missing";
                root.ensureLuaFile();
            } else {
                root.luaFileState = "unknown";
            }
        }
        onSaved: {
            if (root.luaFileState === "creating")
                root.luaFileState = "created";
        }
        onSaveFailed: {
            if (root.luaFileState === "creating") {
                root.luaFileState = "missing";
                ToastService.show(qsTr("Failed to create vast_shell.lua"), qsTr("Hyprland"), "warning", 3000);
            }
        }
    }

    FileView {
        id: rulesLuaFile

        path: root.rulesLuaPath
        watchChanges: false
        onLoaded: root.rulesLuaFileState = "exists"
        onLoadFailed: err => {
            if (err === FileViewError.FileNotFound) {
                root.rulesLuaFileState = "missing";
                root.ensureRulesLuaFile();
            } else {
                root.rulesLuaFileState = "unknown";
            }
        }
        onSaved: {
            if (root.rulesLuaFileState === "creating")
                root.rulesLuaFileState = "created";
        }
        onSaveFailed: {
            if (root.rulesLuaFileState === "creating") {
                root.rulesLuaFileState = "missing";
                ToastService.show(qsTr("Failed to create vast_shell_rules.lua"), qsTr("Hyprland"), "warning", 3000);
            }
        }
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

    Process {
        id: requireCopy

        command: ["sh", "-c", "printf '%s' 'require(\"vast_shell\")' | wl-copy"]
    }

    Process {
        id: requireRulesCopy

        command: ["sh", "-c", "printf '%s' 'require(\"vast_shell_rules\")' | wl-copy"]
    }

    Process {
        id: hyprctlReload

        command: ["hyprctl", "reload"]
    }
}
