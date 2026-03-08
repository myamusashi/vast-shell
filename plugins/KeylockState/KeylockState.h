#pragma once

#include <QObject>
#include <QSocketNotifier>
#include <QQmlEngine>
#include <linux/input.h>

class KeyState : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(bool capsLock READ capsLock NOTIFY capsLockChanged)
    Q_PROPERTY(bool numLock READ numLock NOTIFY numLockChanged)

  public:
    explicit KeyState(QObject* parent = nullptr);
    ~KeyState();

    bool capsLock() const {
        return m_capsLock;
    }
    bool numLock() const {
        return m_numLock;
    }

  signals:
    void capsLockChanged();
    void numLockChanged();

  private slots:
    void onReadReady();

  private:
    void             openDevice();
    void             readInitialState();

    int              m_fd       = -1;
    bool             m_capsLock = false;
    bool             m_numLock  = false;
    QSocketNotifier* m_notifier = nullptr;
};
