#include "KeyEventDecoder.hpp"

#include <linux/input-event-codes.h>

namespace vast {

    KeyEventDecoder::Change KeyEventDecoder::applyEvent(const struct input_event& event, bool ledCapable) noexcept {
        if (ledCapable) {
            // Authoritative: report only a real change. The only path that can
            // turn a lock off.
            if (event.type != EV_LED)
                return Change::None;

            const bool value = event.value != 0;
            if (event.code == LED_CAPSL && mCapsLock != value) {
                mCapsLock = value;
                return Change::CapsLock;
            }
            if (event.code == LED_NUML && mNumLock != value) {
                mNumLock = value;
                return Change::NumLock;
            }
            return Change::None;
        }

        // Inferred: no LED feedback, so toggle unconditionally. Release (0) and
        // auto-repeat (2) are ignored.
        if (event.type != EV_KEY || event.value != 1)
            return Change::None;

        if (event.code == KEY_CAPSLOCK) {
            mCapsLock = !mCapsLock;
            return Change::CapsLock;
        }
        if (event.code == KEY_NUMLOCK) {
            mNumLock = !mNumLock;
            return Change::NumLock;
        }
        return Change::None;
    }

    void KeyEventDecoder::setState(bool capsLock, bool numLock) noexcept {
        mCapsLock = capsLock;
        mNumLock  = numLock;
    }
}
