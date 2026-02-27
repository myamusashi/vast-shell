#pragma once
#include <QJSEngine>
#include <QObject>
#include <QQmlEngine>
#include <QTimer>
#include <QVariantMap>
#include <QtQml/qqmlregistration.h>

#include "AudioProfilesModel.h"

// Exposes PipeWire audio-device profile state to QML.
// The singleton polls the PipeWire thread-loop every 500 ms and emits
// fine-grained change signals so bindings re-evaluate only what changed.

class AudioProfilesWatcher : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    // device id
    Q_PROPERTY(quint32 deviceId READ deviceId NOTIFY deviceInfoChanged)
    Q_PROPERTY(QString deviceName READ deviceName NOTIFY deviceInfoChanged)

    // active profile
    Q_PROPERTY(int activeIndex READ activeIndex NOTIFY activeProfileChanged)
    Q_PROPERTY(QVariantMap activeProfile READ activeProfile NOTIFY activeProfileChanged)

    // QAbstractListModel
    // roles: index, name, description, available, readable
    Q_PROPERTY(AudioProfilesModel* profiles READ profiles CONSTANT)

    // True while the PipeWire connection is up
    Q_PROPERTY(bool connected READ connected NOTIFY connectedChanged)

  public:
    // called once by the QML engine
    static AudioProfilesWatcher* create(QQmlEngine* engine, QJSEngine* jsEngine);

    explicit AudioProfilesWatcher(QObject* parent = nullptr);
    ~AudioProfilesWatcher() override;

    quint32 deviceId() const {
        return m_deviceId;
    }
    QString deviceName() const {
        return m_deviceName;
    }
    int activeIndex() const {
        return m_activeIndex;
    }
    QVariantMap activeProfile() const {
        return m_activeProfile;
    }
    AudioProfilesModel* profiles() const {
        return m_model;
    }
    bool connected() const {
        return m_connected;
    }

  signals:
    void deviceInfoChanged();
    void activeProfileChanged();
    void connectedChanged();

  private slots:
    void poll();

  private:
    // Qt state
    quint32             m_deviceId = 0;
    QString             m_deviceName;
    int                 m_activeIndex = -1;
    QVariantMap         m_activeProfile;
    AudioProfilesModel* m_model     = nullptr;
    QTimer*             m_timer     = nullptr;
    bool                m_connected = false;

    // PipeWire state (opaque to the header)
    struct PwState;
    PwState* m_pw = nullptr;

    // Helpers
    static QString formatProfileName(const QString& name);
};
