#pragma once

#include <qstring.h>
#include <qstringlist.h>
#include <qlatin1stringview.h>

// Turns a raw PipeWire profile name into the label shown to the user. The result
// becomes ProfileEntry::readable, which Qml/Widgets/AudioProfiles.qml renders
// directly through `textRole: "readable"`, so this is user-visible text.
inline QString formatProfileName(const QString& name) {
    if (name == u"off")
        return QStringLiteral("Off");
    if (name == u"pro-audio")
        return QStringLiteral("Pro Audio");

    const QStringList parts = name.split(QLatin1Char('+'));
    QStringList       out;
    out.reserve(parts.size());

    for (QString part : parts) {
        part = part.trimmed();
        if (part.startsWith(QLatin1String("output:")))
            part.remove(0, 7);
        else if (part.startsWith(QLatin1String("input:")))
            part.remove(0, 6);

        QStringList words = part.split(QLatin1Char('-'));
        for (QString& w : words)
            if (!w.isEmpty())
                w.replace(0, 1, w.at(0).toUpper());
        out << words.join(QLatin1Char(' '));
    }
    return out.join(QStringLiteral(" + "));
}
