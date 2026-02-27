#include "AudioProfilesModel.h"

AudioProfilesModel::AudioProfilesModel(QObject* parent) : QAbstractListModel(parent) {}

int AudioProfilesModel::rowCount(const QModelIndex& parent) const {
    if (parent.isValid())
        return 0;
    return static_cast<int>(m_profiles.size());
}

QVariant AudioProfilesModel::data(const QModelIndex& index, int role) const {
    if (!index.isValid() || index.row() >= m_profiles.size())
        return {};

    const ProfileEntry& e = m_profiles.at(index.row());
    switch (role) {
        case IndexRole: return e.index;
        case NameRole: return e.name;
        case DescriptionRole: return e.description;
        case AvailableRole: return e.available;
        case ReadableRole: return e.readable;
        default: return {};
    }
}

QHash<int, QByteArray> AudioProfilesModel::roleNames() const {
    return {
        {IndexRole, QByteArrayLiteral("index")},         {NameRole, QByteArrayLiteral("name")},         {DescriptionRole, QByteArrayLiteral("description")},
        {AvailableRole, QByteArrayLiteral("available")}, {ReadableRole, QByteArrayLiteral("readable")},
    };
}

void AudioProfilesModel::setProfiles(const QList<ProfileEntry>& profiles) {
    beginResetModel();
    m_profiles = profiles;
    endResetModel();
}

QVariantMap AudioProfilesModel::get(int row) const {
    if (row < 0 || row >= m_profiles.size())
        return {};

    const ProfileEntry& e = m_profiles.at(row);
    return {
        {QStringLiteral("index"), e.index},         {QStringLiteral("name"), e.name},         {QStringLiteral("description"), e.description},
        {QStringLiteral("available"), e.available}, {QStringLiteral("readable"), e.readable},
    };
}
