pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

import qs.Core.Utils

Singleton {
    id: root

    property bool loaded: false
    property var  todos: []

    signal        dataChanged

    function      add(text: string, date: var): void {
        const trimmedText = (text || "").trim();
        if (!trimmedText)
            return;
        const entry = {
            id: nextId(),
            text: trimmedText,
            done: false,
            date: isoDate(date || new Date()),
            createdAt: Date.now()
        };
        replaceTodos([...todos, entry]);
    }
    function      clearCompleted(date: var): void {
        const dateKey = date ? isoDate(date) : null;
        replaceTodos(todos.filter(todo => !(todo.done && (dateKey === null || todo.date === dateKey))));
    }
    function      forDate(date: var): var {
        const dateKey = isoDate(date);
        return todos.filter(todo => todo && todo.date === dateKey);
    }
    function      isoDate(date: var): string {
        if (typeof date === "string")
            return date;
        const parsedDate = new Date(date);
        const month      = String(parsedDate.getMonth() + 1).padStart(2, "0");
        const day        = String(parsedDate.getDate()).padStart(2, "0");
        return `${parsedDate.getFullYear()}-${month}-${day}`;
    }
    function      nextId(): int {
        return todos.reduce((highestId, todo) => (todo && todo.id > highestId) ? todo.id : highestId, 0) + 1;
    }
    function      parseTodos(rawText: string): var {
        if (!rawText || !rawText.trim())
            return [];
        try {
            const parsedData = JSON.parse(rawText);
            return Array.isArray(parsedData) ? parsedData : [];
        } catch (error) {
            console.warn("TodoModel: failed to parse todos file:", error);
            return [];
        }
    }
    function      patchTodo(id: int, changes: var): void {
        replaceTodos(todos.map(todo => todo.id === id ? Object.assign({}, todo, changes) : todo));
    }
    function      remove(id: int): void {
        replaceTodos(todos.filter(todo => todo.id !== id));
    }
    function      replaceTodos(updatedTodos: var): void {
        todos = updatedTodos;
        save();
        dataChanged();
    }
    function      save(): void {
        try {
            storage.setText(JSON.stringify(todos));
        } catch (error) {
            console.warn("TodoModel: failed to save todos:", error);
        }
    }
    function      toggle(id: int): void {
        const todo = todos.find(entry => entry.id === id);
        if (todo)
            patchTodo(id, {
                done: !todo.done
            });
    }
    function      update(id: int, text: string): void {
        const trimmedText = (text || "").trim();
        if (trimmedText)
            patchTodo(id, {
                text: trimmedText
            });
    }

    FileView {
        id: storage

        path: Paths.cacheDir + "/vast-shell/todos.json"
        onLoadFailed: {
            root.save();
            root.loaded = true;
        }
        onLoaded: {
            root.todos  = root.parseTodos(storage.text());
            root.loaded = true;
        }
    }
}
