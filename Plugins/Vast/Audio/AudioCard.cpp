#include "AudioCard.hpp"

AudioCard::AudioCard(QObject* parent) : QObject(parent), mProfiles(new AudioProfilesModel(this)) {}

AudioCard::~AudioCard() = default;

bool AudioCard::setDeviceInfo(quint32 deviceId, const QString& name, const QString& description) {
    bool changed = false;
    if (mDeviceId != deviceId) {
        mDeviceId = deviceId;
        Q_EMIT deviceIdChanged();
        changed = true;
    }
    if (mName != name) {
        mName = name;
        Q_EMIT nameChanged();
        changed = true;
    }
    if (mDescription != description) {
        mDescription = description;
        Q_EMIT descriptionChanged();
        changed = true;
    }
    return changed;
}

bool AudioCard::setActiveProfile(qsizetype index, const QVariantMap& profile) {
    if (mActiveIndex == index && mActiveProfile == profile)
        return false;
    mActiveIndex   = index;
    mActiveProfile = profile;
    Q_EMIT activeIndexChanged();
    return true;
}
