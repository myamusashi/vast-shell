#pragma once
#include <QAbstractListModel>
#include <QList>
#include <QVariantMap>
#include <QtQml/qqmlregistration.h>

// ─── Plain data type ─────────────────────────────────────────────────────────

struct ProfileEntry {
    int     index       = -1;
    QString name;
    QString description;
    QString available;
    QString readable;   // human-friendly label, e.g. "Headphones + Microphone"
};

// ─── Model ───────────────────────────────────────────────────────────────────

class AudioProfilesModel : public QAbstractListModel
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("Access via AudioProfilesWatcher.profiles")

public:
    enum Roles {
        IndexRole       = Qt::UserRole + 1,
        NameRole,
        DescriptionRole,
        AvailableRole,
        ReadableRole,
    };
    Q_ENUM(Roles)

    explicit AudioProfilesModel(QObject *parent = nullptr);

    // QAbstractListModel
    int      rowCount(const QModelIndex &parent = {}) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    // Bulk replacement — always from the Qt main thread
    void setProfiles(const QList<ProfileEntry> &profiles);

    // QML helper: returns a plain JS object for row i
    Q_INVOKABLE QVariantMap get(int row) const;
    Q_INVOKABLE int         count() const { return m_profiles.size(); }

private:
    QList<ProfileEntry> m_profiles;
};
