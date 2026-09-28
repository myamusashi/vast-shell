#pragma once

#include <cstdint>
#include <linux/input.h>

namespace vast {

    /// Decodes evdev input_event records into caps/num lock state.
    ///
    /// ledCapable selects the mode. An EV_LED keyboard is authoritative: it
    /// re-sends the LED on every state change, so an unchanged value must
    /// report Change::None. Without EV_LED only the key press is visible, so it
    /// toggles unconditionally and the state may drift.
    class KeyEventDecoder {
      public:
        enum class Change : uint8_t {
            None,
            CapsLock,
            NumLock,
        };

        [[nodiscard]] Change applyEvent(const struct input_event& event, bool ledCapable) noexcept;
        void                 setState(bool capsLock, bool numLock) noexcept;

        [[nodiscard]] bool   capsLock() const noexcept {
            return mCapsLock;
        }
        [[nodiscard]] bool numLock() const noexcept {
            return mNumLock;
        }

      private:
        bool mCapsLock{false};
        bool mNumLock{false};
    };
}
