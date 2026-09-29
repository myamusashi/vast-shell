#pragma once

#include <qlist.h>
#include <qstring.h>
#include <qstringlist.h>

namespace vast::test {

    /// Absolute paths of the fixture images, in manifest order.
    [[nodiscard]] QStringList wallpaperFixtures();

    /// Dominant hue in degrees recorded for the fixture at the same index.
    [[nodiscard]] QList<double> wallpaperFixtureHues();

    /// Fails the calling test with a clear message when the fixture set is
    /// missing, so a partial checkout reports "regenerate fixtures" rather than
    /// a confusing null-image failure deep inside the quantizer.
    bool requireWallpaperFixtures(QString& error);

} // namespace vast::test
