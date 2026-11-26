pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Greetd

import qs.Services
import qs.Core.Utils

Scope {
    id: root

    readonly property bool available: Greetd.available

    property alias         currentText: authFlow.currentText
    property string        currentUser: ""
    property bool          echoResponse: false
    property bool          isUnlock: false
    property string        lastSessionCommand: ""
    property bool          launching: false
    property bool          messageIsError: false
    property int           selectedSessionIndex: -1
    property ListModel     sessions: ListModel {}
    property alias         showFailure: authFlow.showFailure
    property string        statusMessage: ""
    property alias         unlockInProgress: authFlow.inProgress
    property var           users: []

    signal                 launchReady

    function               buildSessionEnvironment(session) {
        const environment = [];
        if (!session)
            return environment;
        if (session.sessionType && session.sessionType.length > 0)
            environment.push("XDG_SESSION_TYPE=" + session.sessionType);
        if (session.sessionId && session.sessionId.length > 0) {
            environment.push("XDG_SESSION_DESKTOP=" + session.sessionId);
            environment.push("DESKTOP_SESSION=" + session.sessionId);
        }
        if (session.desktopNames && session.desktopNames.length > 0)
            environment.push("XDG_CURRENT_DESKTOP=" + session.desktopNames);
        return environment;
    }

    function               launch() {
        if (launching || Greetd.state !== GreetdState.ReadyToLaunch)
            return;
        launching         = true;
        const session     = selectedSession();
        const rawCommand  = session && session.command ? session.command : "bash";
        const commandArgs = parseCommand(rawCommand);
        const environment = buildSessionEnvironment(session);
        Greetd.launch(commandArgs, environment, true);
    }

    function               parseCommand(rawCommand) {
        const text = String(rawCommand ?? "").trim();
        if (text.length === 0)
            return ["bash"];

        const args  = [];
        let current = "";
        let quote   = "";
        let escaped = false;

        for (let i = 0; i < text.length; i++) {
            const ch = text.charAt(i);
            if (escaped) {
                current += ch;
                escaped = false;
                continue;
            }
            if (ch === "\\" && quote !== "'") {
                escaped = true;
                continue;
            }
            if (quote !== "") {
                if (ch === quote)
                    quote = "";
                else
                    current += ch;
                continue;
            }
            if (ch === "'" || ch === "\"") {
                quote = ch;
                continue;
            }
            if (/\s/.test(ch)) {
                if (current.length > 0) {
                    args.push(current);
                    current = "";
                }
                continue;
            }
            current += ch;
        }
        if (current.length > 0)
            args.push(current);

        return args.length > 0 ? args : ["bash"];
    }

    function               saveLastSession(command) {
        if (lastSessionCommand === command)
            return;
        lastSessionCommand = command;
        Quickshell.execDetached({
            command: [Paths.projectRoot + "/Assets/shell/last-session.sh", command]
        });
    }

    function               selectedSession() {
        if (sessions.count === 0)
            return null;
        let index = selectedSessionIndex;
        if (index < 0 || index >= sessions.count)
            index = 0;
        return sessions.get(index);
    }

    function               selectSession(index) {
        if (index < 0 || index >= sessions.count)
            return;
        selectedSessionIndex = index;
        const session        = sessions.get(index);
        if (session && session.command)
            saveLastSession(session.command);
    }

    function               sessionIndexForCommand(command) {
        if (command === "")
            return -1;
        for (let i = 0; i < sessions.count; i++)
            if (sessions.get(i).command === command)
                return i;

        return -1;
    }

    function               switchUser(username) {
        if (currentUser === username || unlockInProgress)
            return;

        currentUser = username;
        authFlow.clear();
        messageIsError = false;
        statusMessage  = "";
    }

    function               tryUnlock() {
        if (currentUser === "")
            return;
        if (Greetd.state !== GreetdState.Inactive)
            return;

        statusMessage  = qsTr("Authenticating…");
        messageIsError = false;
        if (!authFlow.submitSecret())
            return;
        Greetd.createSession(currentUser);
    }

    onCurrentTextChanged: {
        if (showFailure || messageIsError) {
            showFailure    = false;
            messageIsError = false;
            statusMessage  = "";
        }
    }
    onLastSessionCommandChanged: selectSession(sessionIndexForCommand(lastSessionCommand))

    Connections {

        function onAuthFailure(message) {
            authFlow.fail();
            root.messageIsError = true;
            root.statusMessage  = message;
        }

        function onAuthMessage(message, error, responseRequired, echoResponse) {
            root.statusMessage  = message;
            root.messageIsError = error;
            root.echoResponse   = echoResponse;

            if (responseRequired) {
                if (root.currentText.length > 0) {
                    Greetd.respond(root.currentText);
                    authFlow.clear();
                } else {
                    authFlow.inProgress = false;
                }
            }
        }

        function onError(error) {
            root.launching = false;
            authFlow.fail();
            root.messageIsError = true;
            root.statusMessage  = error;
        }

        function onReadyToLaunch() {
            const session = root.selectedSession();
            if (session && session.command)
                root.saveLastSession(session.command);
            root.statusMessage = qsTr("Session Start");
            root.launchReady();
        }

        target: Greetd
    }

    AuthFlow {
        id: authFlow
    }

    Process {
        id: usersProcess

        command: ["awk", "-F:", "/\\/home/ { print $1 }", "/etc/passwd"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n").filter(line => line.length > 0);
                root.users  = lines;
                if (root.currentUser === "" && lines.length > 0)
                    root.currentUser = lines[0];
            }
        }
    }

    Process {
        id: sessionsProcess

        command: [Paths.projectRoot + "/Assets/shell/desktop-session.sh"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n").filter(line => line.length > 0);
                for (const line of lines) {
                    const parts = line.split("|||");
                    if (parts.length < 2)
                        continue;
                    root.sessions.append({
                        display: parts[0],
                        command: parts[1].trim(),
                        sessionType: parts.length > 2 ? parts[2].trim() : "",
                        desktopNames: parts.length > 3 ? parts[3].trim() : "",
                        sessionId: parts.length > 4 ? parts[4].trim() : ""
                    });
                }
                root.selectSession(root.sessionIndexForCommand(root.lastSessionCommand));
            }
        }
    }

    Process {
        id: lastSessionProcess

        command: [Paths.projectRoot + "/Assets/shell/last-session.sh"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const value = text.trim();
                if (value.length > 0)
                    root.lastSessionCommand = value;
            }
        }
    }
}
