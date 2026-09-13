pragma Singleton

import QtQuick
import Quickshell

import qs.Core.Configs

Singleton {
    id: root

    property var current: null
    property var overlay: null
    property var queue: []
    property bool closing: false
    property bool slidingUp: false
    readonly property int slideDuration: 300
    property int _nextId: 1

    readonly property bool hasContent: current !== null || overlay !== null

    // Only an infinite base yields to a finite override (overlay). Every
    // other pairing queues behind the current content.
    function show(content, duration): int {
        if (!content) {
            console.warn("[DynamicIsland] show called without content");
            return -1;
        }
        var durationMs = Number(duration ?? 0);
        if (isNaN(durationMs) || durationMs < 0)
            durationMs = 0;
        var req = {
            id: root._nextId++,
            content: content,
            durationMs: durationMs,
            infinite: !(durationMs > 0)
        };
        if (root.closing) {
            contractTimer.stop();
            slideTimer.stop();
            baseTimer.stop();
            overlayTimer.stop();
            root.closing = false;
            root.slidingUp = false;
            root.current = null;
            root.overlay = null;
        }
        if (root.current === null) {
            if (root.overlay === null) {
                root.current = req;
                if (!req.infinite) {
                    baseTimer.interval = req.durationMs;
                    baseTimer.restart();
                }
                return req.id;
            }
            // An override is on screen with no base behind it: everything
            // queues until the override's timer ends, finite or infinite.
            root.queue = root.queue.concat([req]);
            return req.id;
        }
        if (root.current.infinite && !req.infinite && root.overlay === null) {
            root.overlay = req;
            overlayTimer.interval = req.durationMs;
            overlayTimer.restart();
            return req.id;
        }
        root.queue = root.queue.concat([req]);
        return req.id;
    }

    function dismiss(id): void {
        if (id === undefined || id === null) {
            dismissCurrent();
            return;
        }
        id = Number(id);
        if (root.overlay !== null && root.overlay.id === id) {
            overlayTimer.stop();
            if (root.current === null)
                finishDismissedOverlay();
            else
                root.overlay = null;
            return;
        }
        if (root.current !== null && root.current.id === id) {
            dismissCurrent();
            return;
        }
        for (var i = 0; i < root.queue.length; i++) {
            if (root.queue[i].id === id) {
                var rest = root.queue.slice();
                rest.splice(i, 1);
                root.queue = rest;
                return;
            }
        }
    }

    function dismissCurrent(): void {
        if (root.current === null) {
            if (root.overlay === null)
                return;
            overlayTimer.stop();
            finishDismissedOverlay();
            return;
        }
        baseTimer.stop();
        if (root.overlay !== null) {
            // Base ends behind a finite override; the override keeps showing
            // until its own timer ends, then the queue advances.
            root.current = null;
            return;
        }
        promoteOrClose();
    }

    function beginClose(): void {
        if (root.closing || (root.current === null && root.overlay === null))
            return;
        root.closing = true;
        root.slidingUp = false;
        contractTimer.restart();
        slideTimer.restart();
    }

    function promoteOrClose(): void {
        if (root.queue.length > 0) {
            var pending = root.queue.slice();
            var next = pending.shift();
            root.queue = pending;
            root.current = next;
            if (!next.infinite) {
                baseTimer.interval = next.durationMs;
                baseTimer.restart();
            }
        } else {
            root.beginClose();
        }
    }

    function finishDismissedOverlay(): void {
        if (root.queue.length > 0) {
            var pending = root.queue.slice();
            var next = pending.shift();
            root.queue = pending;
            root.overlay = null;
            root.current = next;
            if (!next.infinite) {
                baseTimer.interval = next.durationMs;
                baseTimer.restart();
            }
        } else {
            root.beginClose();
        }
    }

    function _expireBase(): void {
        if (root.current === null || root.closing)
            return;
        root.promoteOrClose();
    }

    function _expireOverlay(): void {
        if (root.overlay === null || root.closing)
            return;
        if (root.current !== null) {
            // Finite override ends; the infinite base resumes untouched.
            root.overlay = null;
            return;
        }
        root.overlay = null;
        root.promoteOrClose();
    }

    function _finishClose(): void {
        contractTimer.stop();
        slideTimer.stop();
        baseTimer.stop();
        overlayTimer.stop();
        root.current = null;
        root.overlay = null;
        root.closing = false;
        root.slidingUp = false;
        // A queued request that arrived mid-close promotes immediately so
        // the shell stays alive and shows it without tearing down.
        if (root.queue.length > 0) {
            var pending = root.queue.slice();
            var next = pending.shift();
            root.queue = pending;
            root.current = next;
            if (!next.infinite) {
                baseTimer.interval = next.durationMs;
                baseTimer.restart();
            }
        }
    }

    Timer {
        id: baseTimer

        repeat: false
        onTriggered: root._expireBase()
    }

    Timer {
        id: overlayTimer

        repeat: false
        onTriggered: root._expireOverlay()
    }

    Timer {
        id: contractTimer

        interval: Appearance.animations.durations.expressiveDefaultSpatial
        onTriggered: root.slidingUp = true
    }

    Timer {
        id: slideTimer

        interval: Appearance.animations.durations.expressiveDefaultSpatial + 300
        onTriggered: root._finishClose()
    }
}
