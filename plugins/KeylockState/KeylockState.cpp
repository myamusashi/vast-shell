#include "KeylockState.h"

#include <QDir>
#include <fcntl.h>
#include <unistd.h>
#include <sys/ioctl.h>
#include <linux/input.h>
#include <linux/kd.h>

static QList<KeyboardDevice> findKeyboards() {
    QList<KeyboardDevice> devices;
    QDir                  inputDir("/dev/input");
    const auto            entries = inputDir.entryList({"event*"}, QDir::System);

    for (const QString& entry : entries) {
        const QByteArray path = ("/dev/input/" + entry).toLocal8Bit();
        int              fd   = ::open(path.constData(), O_RDONLY | O_NONBLOCK);
        if (fd < 0)
            continue;

        // check what event types this device supports
        unsigned long evBits = 0;
        if (::ioctl(fd, EVIOCGBIT(0, sizeof(evBits)), &evBits) < 0) {
            ::close(fd);
            continue;
        }

        // must have EV_KEY
        if (!(evBits & (1UL << EV_KEY))) {
            ::close(fd);
            continue;
        }

        // must have KEY_CAPSLOCK
        unsigned long keyBits[(KEY_MAX / 8) + 1] = {};
        if (::ioctl(fd, EVIOCGBIT(EV_KEY, sizeof(keyBits)), keyBits) < 0) {
            ::close(fd);
            continue;
        }

        const bool hasCapsKey = keyBits[KEY_CAPSLOCK / 8] & (1 << (KEY_CAPSLOCK % 8));
        if (!hasCapsKey) {
            ::close(fd);
            continue;
        }

        const bool hasLED = evBits & (1UL << EV_LED);
        devices.append({fd, hasLED});

        qDebug("KeylockState: found %s (%s LED)", path.constData(), hasLED ? "with" : "without");
    }

    return devices;
}

KeylockState::KeylockState(QObject* parent) : QObject(parent) {
    openDevices();
}

KeylockState::~KeylockState() {
    qDeleteAll(m_notifiers);
    m_notifiers.clear();

    for (int fd : m_fds)
        ::close(fd);
    m_fds.clear();
}

void KeylockState::openDevices() {
    const auto devices = findKeyboards();
    if (devices.isEmpty()) {
        qWarning("KeylockState: no keyboard found");
        return;
    }

    // Track fds immediately, before anything can throw
    for (const auto& dev : devices)
        m_fds.append(dev.fd);

    readInitialState(devices.first().fd, devices.first().hasLED);

    for (const auto& dev : devices) {
        auto* notifier = new QSocketNotifier(dev.fd, QSocketNotifier::Read);
        connect(notifier, &QSocketNotifier::activated, this, [this, fd = dev.fd, hasLED = dev.hasLED]() { onReadReady(fd, hasLED); });
        m_notifiers.append(notifier);
    }
}

void KeylockState::readInitialState(int fd, bool hasLED) {
    if (hasLED) {
        unsigned char ledBits[LED_MAX / 8 + 1] = {};
        if (::ioctl(fd, EVIOCGLED(sizeof(ledBits)), ledBits) < 0)
            return;
        m_capsLock = ledBits[LED_CAPSL / 8] & (1 << (LED_CAPSL % 8));
        m_numLock  = ledBits[LED_NUML / 8] & (1 << (LED_NUML % 8));
    } else {
        // Try VT first
        int ttyFd = ::open("/dev/tty", O_RDONLY);
        if (ttyFd >= 0) {
            unsigned char flags = 0;
            if (::ioctl(ttyFd, KDGKBLED, &flags) == 0) {
                m_capsLock = flags & LED_CAP;
                m_numLock  = flags & LED_NUM;
            }
            ::close(ttyFd);
        } else {
            // /dev/tty unavailable, read key state bitmap from evdev
            unsigned long keyState[(KEY_MAX / 8) + 1] = {};
            if (::ioctl(fd, EVIOCGKEY(sizeof(keyState)), keyState) == 0) {
                // EVIOCGKEY gives currently held keys, not toggle state
                // so we can only default to false here, no reliable fallback
                qWarning("KeylockState: /dev/tty unavailable, initial state unknown");
            }
        }
    }
}

void KeylockState::onReadReady(int fd, bool hasLED) {
    input_event ev{};
    while (::read(fd, &ev, sizeof(ev)) == sizeof(ev)) {
        if (hasLED) {
            if (ev.type != EV_LED)
                continue;
            const bool val = ev.value != 0;
            if (ev.code == LED_CAPSL && m_capsLock != val) {
                m_capsLock = val;
                emit capsLockChanged();
            } else if (ev.code == LED_NUML && m_numLock != val) {
                m_numLock = val;
                emit numLockChanged();
            }
        } else {
            if (ev.type != EV_KEY || ev.value != 1)
                continue;
            if (ev.code == KEY_CAPSLOCK) {
                m_capsLock = !m_capsLock;
                emit capsLockChanged();
            } else if (ev.code == KEY_NUMLOCK) {
                m_numLock = !m_numLock;
                emit numLockChanged();
            }
        }
    }
}
