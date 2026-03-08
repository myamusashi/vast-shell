#include "KeylockState.h"

#include <QDir>
#include <fcntl.h>
#include <unistd.h>
#include <linux/input.h>
#include <sys/ioctl.h>

static int findKeyboardFd() {
    QDir       inputDir("/dev/input");
    const auto entries = inputDir.entryList({"event*"}, QDir::System);
    for (const QString& entry : entries) {
        const QByteArray path = ("/dev/input/" + entry).toLocal8Bit();
        int              fd   = ::open(path.constData(), O_RDONLY | O_NONBLOCK);
        if (fd < 0)
            continue;

        unsigned long evBits = 0;
        if (::ioctl(fd, EVIOCGBIT(0, sizeof(evBits)), &evBits) >= 0) {
            if (evBits & (1 << EV_LED))
                return fd;
        }
        ::close(fd);
    }
    return -1;
}

KeyState::KeyState(QObject* parent) : QObject(parent) {
    openDevice();
}

KeyState::~KeyState() {
    if (m_fd >= 0)
        ::close(m_fd);
}

void KeyState::openDevice() {
    m_fd = findKeyboardFd();
    if (m_fd < 0) {
        qWarning("KeyState: no keyboard LED device found");
        return;
    }

    readInitialState();

    // QSocketNotifier watches the fd — fires onReadReady when kernel pushes events
    m_notifier = new QSocketNotifier(m_fd, QSocketNotifier::Read, this);
    connect(m_notifier, &QSocketNotifier::activated, this, &KeyState::onReadReady);
}

void KeyState::readInitialState() {
    // EVIOCGLED reads current LED bitmask directly from the kernel
    unsigned char ledBits[LED_MAX / 8 + 1] = {};
    if (::ioctl(m_fd, EVIOCGLED(sizeof(ledBits)), ledBits) < 0)
        return;

    m_capsLock = ledBits[LED_CAPSL / 8] & (1 << (LED_CAPSL % 8));
    m_numLock  = ledBits[LED_NUML / 8] & (1 << (LED_NUML % 8));
}

void KeyState::onReadReady() {
    input_event ev{};
    while (::read(m_fd, &ev, sizeof(ev)) == sizeof(ev)) {
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
    }
}
