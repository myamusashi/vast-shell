#include <qdir.h>
#include <qfile.h>
#include <qjsondocument.h>
#include <qjsonobject.h>
#include <qlist.h>
#include <qmap.h>
#include <qstring.h>
#include <qstringlist.h>
#include <qtest.h>

#include "PaletteBuilder.hpp"
#include "PaletteValidation.hpp"

#ifndef VAST_TEST_GOLDEN_DIR
#error "VAST_TEST_GOLDEN_DIR must be defined by the build"
#endif

// One reference palette plus the inputs needed to re-derive it.
struct SGolden {
    QString                name;
    QString                mode;
    QString                sourceColor;
    QMap<QString, QString> colors;
};

// QFETCH is function-like, so a type containing a comma needs a typedef.
using TExpected = QMap<QString, QString>;

namespace {

    QList<SGolden> loadGoldens() {
        QList<SGolden> goldens;
        const QDir     dir(QString::fromLatin1(VAST_TEST_GOLDEN_DIR));
        for (const QString& name : dir.entryList({QStringLiteral("*.json")}, QDir::Files, QDir::Name)) {
            QFile file(dir.filePath(name));
            if (!file.open(QIODevice::ReadOnly))
                continue;

            const QJsonObject colors = QJsonDocument::fromJson(file.readAll()).object().value(QStringLiteral("colors")).toObject();
            SGolden           golden;
            golden.name        = name;
            golden.mode        = name.contains(QLatin1String("light")) ? QStringLiteral("light") : QStringLiteral("dark");
            golden.sourceColor = colors.value(QStringLiteral("sourceColor")).toString();
            for (auto it = colors.constBegin(); it != colors.constEnd(); ++it)
                golden.colors.insert(it.key(), it.value().toString().toUpper());
            goldens.append(golden);
        }
        return goldens;
    }

} // namespace

// Spec parity: every role must match the reference implementation byte for
// byte. The goldens in data/golden/ record the source color they were built
// from, so the palette re-derives without shipping the source images.
//
// tst_palette asserts properties a palette must have; this asserts the values,
// which is what catches tone-table or spec-gating drift.
class TestSpecParity : public QObject {
    Q_OBJECT

  private Q_SLOTS:
    void initTestCase();

    void reproducesReferencePalette_data();
    void reproducesReferencePalette();
    void referencePalettesAreThemselvesValid_data();
    void referencePalettesAreThemselvesValid();
};

void TestSpecParity::initTestCase() {
    QVERIFY2(loadGoldens().size() >= 10, "reference palette fixtures are missing from data/golden/");
}

void TestSpecParity::reproducesReferencePalette_data() {
    QTest::addColumn<QString>("sourceColor");
    QTest::addColumn<QString>("mode");
    QTest::addColumn<TExpected>("expected");
    for (const SGolden& golden : loadGoldens())
        QTest::newRow(qPrintable(golden.name.toUtf8().constData())) << golden.sourceColor << golden.mode << golden.colors;
}

void TestSpecParity::reproducesReferencePalette() {
    QFETCH(QString, sourceColor);
    QFETCH(QString, mode);
    QFETCH(TExpected, expected);

    const SMaterialPaletteResult result = buildPaletteFromColor(sourceColor, mode, QStringLiteral("tonal-spot"), false);
    QVERIFY2(result.error.isEmpty(), qPrintable(result.error));

    QStringList mismatches;
    for (auto it = expected.constBegin(); it != expected.constEnd(); ++it) {
        const QString actual = result.colors.value(it.key()).toUpper();
        if (actual != it.value())
            mismatches.append(QStringLiteral("%1: %2 != %3").arg(it.key(), actual, it.value()));
    }

    QVERIFY2(mismatches.isEmpty(),
             qPrintable(QStringLiteral("%1 of %2 roles differ from the reference:\n%3").arg(mismatches.size()).arg(expected.size()).arg(mismatches.join(QStringLiteral("\n")))));
    QCOMPARE(result.colors.value(QStringLiteral("sourceColor")).toUpper(), sourceColor.toUpper());
}

// The goldens must themselves validate, or a broken run could ratify them.
void TestSpecParity::referencePalettesAreThemselvesValid_data() {
    reproducesReferencePalette_data();
}

void TestSpecParity::referencePalettesAreThemselvesValid() {
    QFETCH(TExpected, expected);

    QString error;
    QVERIFY2(validatePalette(expected, error), qPrintable(error));
}

QTEST_MAIN(TestSpecParity)
#include "tst_spec_parity.moc"
