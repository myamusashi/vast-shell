#pragma once

#include <qobject.h>
#include <qqmlintegration.h>
#include <qstring.h>

class ColorPreview : public QObject {
    Q_OBJECT
    QML_ELEMENT

  public:
    explicit ColorPreview(QObject* parent = nullptr);

    Q_INVOKABLE static QString generate(const QString& imagePath, const QString& mode, const QString& scheme);
    Q_INVOKABLE static QString generateFromColor(const QString& colorHex, const QString& mode, const QString& scheme);
};
