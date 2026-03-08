pragma Singleton

import QtCore
import QtQuick
import Quickshell

Singleton {
    readonly property real prefixWeight: 0.30
    readonly property real distanceWeight: 0.20 // reduced to make room for acronym
    readonly property real consecutiveWeight: 0.15
    readonly property real wordBoundaryWeight: 0.10
    readonly property real acronymWeight: 0.25 // handles "vsc" → "Visual Studio Code"
    readonly property real recencyWeight: 0.4

    readonly property var charMap: ({
            "a": 'aàáâãäåāăą4@',
            "e": 'eèéêëēėę3',
            "i": 'iìíîïīįı1!|l',
            "o": 'oòóôõöøōő0',
            "u": 'uùúûüūůű',
            "c": 'cçćč',
            "n": 'nñńň',
            "s": 'sśšş5$',
            "z": 'zźżž2',
            "l": 'l1!|i',
            "g": 'g9',
            "t": 't7+'
        })

    // pre-built reverse map for O(1) char normalization
    // built once from charMap instead of scanning all values per character
    readonly property var charLookup: {
        let map = {};
        for (const key in charMap) {
            const chars = charMap[key];
            for (let i = 0; i < chars.length; i++)
                map[chars[i]] = key;
        }
        return map;
    }

    property var launchHistory: []

    Settings {
        id: settings

        Component.onCompleted: {
            Qt.application.name = "myamusashi";
            Qt.application.organization = "vast-shell";
        }
    }

    function loadLaunchHistory(): void {
        const stored = settings.value("launchHistory", "[]");
        try {
            launchHistory = JSON.parse(stored);
        } catch (e) {
            launchHistory = [];
        }
    }

    function saveLaunchHistory(): void {
        settings.setValue("launchHistory", JSON.stringify(launchHistory));
    }

    function updateLaunchHistory(entry: DesktopEntry): void {
        const appId = entry.id || entry.name;
        const now = Date.now();

        let found = false;
        for (let i = 0; i < launchHistory.length; i++) {
            if (launchHistory[i].id === appId) {
                launchHistory[i].timestamp = now;
                launchHistory[i].count = (launchHistory[i].count || 0) + 1;
                found = true;
                break;
            }
        }

        if (!found)
            launchHistory.push({
                id: appId,
                timestamp: now,
                count: 1
            });

        if (launchHistory.length > 50) {
            launchHistory.sort((a, b) => b.timestamp - a.timestamp);
            launchHistory = launchHistory.slice(0, 50);
        }

        saveLaunchHistory();
    }

    function getRecencyScore(entry: DesktopEntry): real {
        const appId = entry.id || entry.name;
        const now = Date.now();

        for (let i = 0; i < launchHistory.length; i++) {
            if (launchHistory[i].id === appId) {
                const age = now - launchHistory[i].timestamp;
                const dayInMs = 86400000;
                const recencyScore = Math.exp(-age / (dayInMs * 7));
                const frequencyScore = Math.min(launchHistory[i].count / 10, 1);
                return recencyScore * 0.7 + frequencyScore * 0.3;
            }
        }

        return 0;
    }

    function normalizeChar(c: string): string {
        const lower = c.toLowerCase();
        const mapped = charLookup[lower];
        return mapped !== undefined ? mapped : lower;
    }

    function normalizeText(text: string): string {
        let result = '';
        for (let i = 0; i < text.length; i++)
            result += normalizeChar(text[i]);
        return result;
    }

    function escapeHtml(text) {
        if (!text)
            return "";
        return text.toString().replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;').replace(/'/g, '&#039;');
    }

    function getHighlightedText(text, query, highlightColor) {
        if (!query || query.trim().length === 0)
            return escapeHtml(text);

        const normalizedQuery = normalizeText(query).trim();
        if (normalizedQuery.length === 0)
            return escapeHtml(text);

        const normalizedText = normalizeText(text);

        let result = "";
        let lastIndex = 0;
        let index = normalizedText.indexOf(normalizedQuery);

        while (index !== -1) {
            if (index > lastIndex)
                result += escapeHtml(text.substring(lastIndex, index));

            result += `<span style="color: ${highlightColor}; font-weight: 600;">`;
            result += escapeHtml(text.substring(index, index + normalizedQuery.length));
            result += `</span>`;

            lastIndex = index + normalizedQuery.length;
            index = normalizedText.indexOf(normalizedQuery, lastIndex);
        }

        if (lastIndex < text.length)
            result += escapeHtml(text.substring(lastIndex));

        return result;
    }

    // returns true if every character in q appears in t in order (subsequence check)
    // much faster than Levenshtein and catches "frf" → "Firefox" style matches
    function isSubsequence(q: string, t: string): bool {
        let qi = 0;
        for (let i = 0; i < t.length && qi < q.length; i++) {
            if (t[i] === q[qi])
                qi++;
        }
        return qi === q.length;
    }

    // score how well q matches t as a subsequence
    function subsequenceScore(q: string, t: string): real {
        if (q.length === 0)
            return 1;
        let score = 0;
        let qi = 0;
        let consecutive = 0;
        let bonus = 0;
        for (let i = 0; i < t.length && qi < q.length; i++) {
            if (t[i] === q[qi]) {
                consecutive++;
                // bonus for consecutive matches and word-start matches
                bonus += consecutive * (i === 0 || t[i - 1] === ' ' ? 2 : 1);
                qi++;
            } else {
                consecutive = 0;
            }
        }
        if (qi < q.length)
            return 0; // not a full subsequence
        // max possible bonus is if all chars are consecutive at start
        const maxBonus = q.length * (q.length + 1); // rough upper bound
        return Math.min(bonus / maxBonus, 1);
    }

    // if the length gap alone exceeds maxDist, skip
    function levenshteinDistance(a: string, b: string): int {
        if (a.length === 0)
            return b.length;
        if (b.length === 0)
            return a.length;

        const shorter = a.length <= b.length ? a : b;
        const longer = a.length <= b.length ? b : a;

        let prevRow = new Array(shorter.length + 1);
        let currRow = new Array(shorter.length + 1);
        for (let i = 0; i <= shorter.length; i++)
            prevRow[i] = i;

        for (let i = 1; i <= longer.length; i++) {
            currRow[0] = i;
            let rowMin = currRow[0];
            for (let j = 1; j <= shorter.length; j++) {
                const cost = longer[i - 1] === shorter[j - 1] ? 0 : 1;
                currRow[j] = Math.min(prevRow[j] + 1, currRow[j - 1] + 1, prevRow[j - 1] + cost);
                rowMin = Math.min(rowMin, currRow[j]);
            }
            if (rowMin > shorter.length)
                return rowMin;
            [prevRow, currRow] = [currRow, prevRow];
        }
        return prevRow[shorter.length];
    }

    function distanceScore(a: string, b: string): real {
        const maxLen = Math.max(a.length, b.length);
        if (maxLen === 0)
            return 1;
        // skip Levenshtein when length difference alone makes a good match impossible
        if (Math.abs(a.length - b.length) / maxLen > 0.7)
            return 0;
        const distance = levenshteinDistance(a, b);
        return Math.pow((maxLen - distance) / maxLen, 1.5);
    }

    function prefixScore(q: string, t: string, tWords: var): real {
        if (t.indexOf(q) === 0)
            return q.length === t.length ? 1.0 : 0.95;
        for (let i = 0; i < tWords.length; i++)
            if (tWords[i].indexOf(q) === 0)
                return q.length === tWords[i].length ? 0.9 : 0.85;
        return 0;
    }

    function wordBoundaryScore(q: string, tWords: var): real {
        let bestScore = 0;
        for (let i = 0; i < tWords.length; i++) {
            const word = tWords[i];
            if (word.indexOf(q) !== -1)
                bestScore = Math.max(bestScore, q.length / word.length);
        }
        return bestScore;
    }

    // "vsc" matches "Visual Studio Code" via word initials
    function acronymScore(q: string, tWords: var): real {
        if (tWords.length < 2 || q.length === 0)
            return 0;
        let acronym = '';
        for (let i = 0; i < tWords.length; i++)
            if (tWords[i].length > 0)
                acronym += tWords[i][0];

        if (acronym === q)
            return 1.0;
        if (acronym.indexOf(q) === 0)
            return 0.9;
        if (acronym.indexOf(q) !== -1)
            return 0.75;
        if (isSubsequence(q, acronym))
            return 0.6;
        return 0;
    }

    // score a single normalized query against pre-computed normalized text + words
    function getScore(q: string, t: string, tWords: var): real {
        if (t === q)
            return 1.0;
        if (t.indexOf(q) !== -1)
            return 0.95;

        // acronym match, catches "vsc" → "Visual Studio Code"
        const acro = acronymScore(q, tWords);
        if (acro > 0)
            return acro * acronymWeight + prefixScore(q, t, tWords) * prefixWeight + wordBoundaryScore(q, tWords) * wordBoundaryWeight;

        const lenRatio = Math.min(q.length, t.length) / Math.max(q.length, t.length);
        if (lenRatio < 0.3 && !isSubsequence(q, t))
            return 0;

        // replaces old consecutiveScore, more forgiving
        const subseq = subsequenceScore(q, t) * consecutiveWeight;

        // only run Levenshtein when strings are close enough in length
        const distance = distanceScore(q, t) * distanceWeight;
        const prefix = prefixScore(q, t, tWords) * prefixWeight;
        const wordBnd = wordBoundaryScore(q, tWords) * wordBoundaryWeight;

        return distance + prefix + subseq + wordBnd;
    }

    // split a multi-word query and score each word, then combine
    // "fire fox" will match "Firefox" even though it's one word
    function getMultiWordScore(qWords: var, t: string, tWords: var): real {
        if (qWords.length === 1)
            return getScore(qWords[0], t, tWords);

        let total = 0;
        let matched = 0;
        for (let i = 0; i < qWords.length; i++) {
            const s = getScore(qWords[i], t, tWords);
            if (s > 0) {
                total += s;
                matched++;
            }
        }
        // Require all query words to contribute for multi-word queries
        if (matched < qWords.length)
            return 0;
        return total / qWords.length;
    }

    function fuzzySearch(items: var, query: string, key: string, threshold: real, recencyScoreFn: var): var {
        if (typeof threshold === 'undefined')
            threshold = 0.55;

        const hasQuery = query && query.length > 0;

        // no query → sort by recency only
        if (!hasQuery) {
            if (typeof recencyScoreFn === 'function') {
                let results = [];
                for (let i = 0; i < items.length; i++) {
                    const item = items[i];
                    results.push({
                        item,
                        score: recencyScoreFn(item)
                    });
                }
                results.sort((a, b) => b.score - a.score);
                return results.map(r => r.item);
            }
            return items;
        }

        const normalizedQuery = normalizeText(query).trim();
        if (normalizedQuery.length === 0)
            return items;

        const queryWords = normalizedQuery.split(/\s+/).filter(w => w.length > 0);

        let results = [];
        for (let i = 0; i < items.length; i++) {
            const item = items[i];
            const searchText = key ? item[key] : item;
            if (typeof searchText !== 'string')
                continue;

            const normalizedText = normalizeText(searchText);
            const tWords = normalizedText.split(/\s+/).filter(w => w.length > 0);

            let fuzzyScore = 0;

            if (normalizedText === normalizedQuery)
                fuzzyScore = 1.0;
            else if (normalizedText.indexOf(normalizedQuery) !== -1)
                fuzzyScore = 0.95;
            else
                fuzzyScore = getMultiWordScore(queryWords, normalizedText, tWords);

            if (fuzzyScore >= threshold) {
                let finalScore = fuzzyScore;
                if (typeof recencyScoreFn === 'function') {
                    const recency = recencyScoreFn(item);
                    finalScore = fuzzyScore + recency * recencyWeight;
                }
                results.push({
                    item,
                    score: finalScore
                });
            }
        }

        results.sort((a, b) => {
            const diff = b.score - a.score;
            if (Math.abs(diff) < 0.001) {
                const aText = key ? a.item[key] : a.item;
                const bText = key ? b.item[key] : b.item;
                return aText.length - bText.length;
            }
            return diff;
        });

        return results.map(r => r.item);
    }
}
