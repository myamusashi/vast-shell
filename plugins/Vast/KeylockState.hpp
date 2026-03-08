#pragma once

#include <QList>
#include <QObject>
#include <QSocketNotifier>
#include <QQmlEngine>
#include <linux/input.h>

struct KeyboardDevice {
    int  fd;
    bool hasLED;
};

class Keylock : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(bool capsLock READ capsLock NOTIFY capsLockChanged)
    Q_PROPERTY(bool numLock READ numLock NOTIFY numLockChanged)

  public:
    explicit Keylock(QObject* parent = nullptr);
    ~Keylock();

    bool capsLock() const {
        return m_capsLock;
    }
    bool numLock() const {
        return m_numLock;
    }

  signals:
    void capsLockChanged();
    void numLockChanged();

  private:
    void                    openDevices();
    void                    readInitialState(int fd, bool hasLED);
    void                    onReadReady(int fd, bool hasLED);

    QList<int>              m_fds;
    QList<QSocketNotifier*> m_notifiers;
    bool                    m_capsLock = false;
    bool                    m_numLock  = false;
};
