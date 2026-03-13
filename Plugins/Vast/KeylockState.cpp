#include "KeylockState.hpp"

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

        unsigned long evBits = 0;
        if (::ioctl(fd, EVIOCGBIT(0, sizeof(evBits)), &evBits) < 0) {
            ::close(fd);
            continue;
        }

        const bool hasKey = evBits & (1UL << EV_KEY);
        const bool hasLED = evBits & (1UL << EV_LED);

        if (!hasKey) {
            ::close(fd);
            continue;
        }

        std::array<unsigned char, (KEY_MAX / 8) + 1> keyBits{};
        if (::ioctl(fd, EVIOCGBIT(EV_KEY, keyBits.size()), keyBits.data()) < 0) {
            ::close(fd);
            continue;
        }

        const bool hasCapsKey = keyBits[KEY_CAPSLOCK / 8] & (1 << (KEY_CAPSLOCK % 8));

        if (!hasCapsKey) {
            ::close(fd);
            continue;
        }

        devices.append({fd, hasLED});
    }

    return devices;
}

Keylock::Keylock(QObject* parent) : QObject(parent) {
    openDevices();
}

Keylock::~Keylock() {
    std::ranges::for_each(m_open, [](const OpenDevice& d) {
        delete d.notifier;
        if (d.fd >= 0)
            ::close(d.fd);
    });
}

void Keylock::openDevices() {
    const auto devices = findKeyboards();

    qDebug() << "KeylockState: found" << devices.size() << "device(s)";

    if (devices.isEmpty()) {
        qWarning("KeylockState: no keyboard found — check /dev/input permissions");
        return;
    }

    for (const auto& dev : devices) {
        auto* notifier = new QSocketNotifier(dev.fd, QSocketNotifier::Read);
        connect(notifier, &QSocketNotifier::activated, this, [this, fd = dev.fd, hasLED = dev.hasLED] { onReadReady(fd, hasLED); });
        m_open.push_back({dev.fd, notifier});
    }
}

void Keylock::readInitialState(int fd, bool hasLED) {
    if (hasLED) {
        std::array<unsigned char, LED_MAX / 8 + 1> ledBits{};
        if (::ioctl(fd, EVIOCGLED(ledBits.size()), ledBits.data()) < 0)
            return;

        m_capsLock = ledBits[LED_CAPSL / 8] & (1 << (LED_CAPSL % 8));
        m_numLock  = ledBits[LED_NUML / 8] & (1 << (LED_NUML % 8));
    } else {
        int ttyFd = ::open("/dev/tty", O_RDONLY);
        if (ttyFd >= 0) {
            unsigned char flags = 0;
            if (::ioctl(ttyFd, KDGKBLED, &flags) == 0) {
                m_capsLock = flags & LED_CAP;
                m_numLock  = flags & LED_NUM;
            }
            ::close(ttyFd);
        } else {
            unsigned long keyState[(KEY_MAX / 8) + 1] = {};
            // EVIOCGKEY gives currently held keys, not toggle state
            // so we can only default to false here, no reliable fallback
            if (::ioctl(fd, EVIOCGKEY(sizeof(keyState)), keyState) == 0)
                qWarning("Keylock: /dev/tty unavailable, initial state unknown");
        }
    }
}

void Keylock::onReadReady(int fd, bool hasLED) {
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
