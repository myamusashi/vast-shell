#include <qdir.h>
#include <qfile.h>
#include <qjsondocument.h>
#include <qset.h>
#include <qjsonobject.h>
#include <qlist.h>
#include <qstring.h>
#include <qstringlist.h>
#include <qtest.h>

#include "ImageQuantizer.hpp"
#include "PaletteBuilder.hpp"

#ifndef VAST_TEST_QUANTIZER_DIR
#error "VAST_TEST_QUANTIZER_DIR must be defined by the build"
#endif
#ifndef VAST_TEST_QUANTIZER_GOLDEN_DIR
#error "VAST_TEST_QUANTIZER_GOLDEN_DIR must be defined by the build"
#endif

namespace {

    struct SQuantizerGolden {
        QString file;
        QString sourceColor;
    };

    QList<SQuantizerGolden> loadGoldens() {
        QList<SQuantizerGolden> goldens;
        const QString           manifestPath = QDir(QString::fromLatin1(VAST_TEST_QUANTIZER_GOLDEN_DIR)).filePath(QStringLiteral("manifest.json"));
        QFile                   file(manifestPath);
        if (!file.open(QIODevice::ReadOnly))
            return goldens;

        const QJsonObject root = QJsonDocument::fromJson(file.readAll()).object();
        for (auto it = root.constBegin(); it != root.constEnd(); ++it) {
            const QJsonObject entry = it.value().toObject();
            goldens.append({entry.value(QStringLiteral("file")).toString(), entry.value(QStringLiteral("sourceColor")).toString().toUpper()});
        }
        return goldens;
    }

} // namespace

// Quantizer parity: image bytes -> sourceColor, the step before the one
// tst_spec_parity covers. ImageQuantizer reimplements Pillow's bicubic
// resample, so it is compared against the reference here.
//
// The quantizer is not scale-invariant, so the goldens must be generated from
// these exact fixture bytes; build_quantizer_fixtures.py does both.
class TestQuantizerParity : public QObject {
    Q_OBJECT

  private Q_SLOTS:
    void initTestCase();

    void matchesReferenceSourceColor_data();
    void matchesReferenceSourceColor();
    void isDeterministic_data();
    void isDeterministic();
    void survivesEveryBitmapSize_data();
    void survivesEveryBitmapSize();
    void rescalePathVariesWithBitmapSize();
};

void TestQuantizerParity::initTestCase() {
    const QList<SQuantizerGolden> goldens = loadGoldens();
    QVERIFY2(goldens.size() == 5, "quantizer goldens are missing from data/quantizer-golden/");
    for (const SQuantizerGolden& golden : goldens)
        QVERIFY2(!golden.sourceColor.isEmpty(), "a quantizer golden has no recorded sourceColor");
}

void TestQuantizerParity::matchesReferenceSourceColor_data() {
    QTest::addColumn<QString>("file");
    QTest::addColumn<QString>("sourceColor");
    for (const SQuantizerGolden& golden : loadGoldens())
        QTest::newRow(qPrintable(golden.file.toUtf8().constData())) << golden.file << golden.sourceColor;
}

void TestQuantizerParity::matchesReferenceSourceColor() {
    QFETCH(QString, file);
    QFETCH(QString, sourceColor);

    const QString path = QDir(QString::fromLatin1(VAST_TEST_QUANTIZER_DIR)).filePath(file);
    const auto    argb = quantizeImage(path, 128);
    const QString hex  = QStringLiteral("#%1").arg(argb & 0xFFFFFF, 6, 16, QChar('0')).toUpper();

    QCOMPARE(hex, sourceColor);
}

void TestQuantizerParity::isDeterministic_data() {
    matchesReferenceSourceColor_data();
}

void TestQuantizerParity::isDeterministic() {
    QFETCH(QString, file);
    QFETCH(QString, sourceColor);

    const QString path   = QDir(QString::fromLatin1(VAST_TEST_QUANTIZER_DIR)).filePath(file);
    const auto    first  = quantizeImage(path, 128);
    const auto    second = quantizeImage(path, 128);
    QCOMPARE(first, second);
}

void TestQuantizerParity::survivesEveryBitmapSize_data() {
    QTest::addColumn<QString>("file");
    for (const SQuantizerGolden& golden : loadGoldens())
        QTest::newRow(qPrintable(golden.file.toUtf8().constData())) << golden.file;
}

// Every bitmap size must produce a usable accent. Size sensitivity is checked
// in aggregate: a flat region can dominate at every size.
void TestQuantizerParity::survivesEveryBitmapSize() {
    QFETCH(QString, file);

    const QString path = QDir(QString::fromLatin1(VAST_TEST_QUANTIZER_DIR)).filePath(file);
    for (const int size : {32, 64, 128, 256}) {
        const auto argb = quantizeImage(path, size);
        QVERIFY2(argb != 0, qPrintable(QStringLiteral("quantizer returned black at %1px").arg(size)));
    }
}

// Guards the rescale path: without it every size returns the same accent and
// the per-image checks still pass. Observed spread is 13 colors.
void TestQuantizerParity::rescalePathVariesWithBitmapSize() {
    const QDir    dir(QString::fromLatin1(VAST_TEST_QUANTIZER_DIR));
    QSet<quint32> seen;
    for (const SQuantizerGolden& golden : loadGoldens()) {
        const QString path = dir.filePath(golden.file);
        for (const int size : {32, 64, 128, 256})
            seen.insert(quantizeImage(path, size));
    }
    QVERIFY2(seen.size() >= 8, qPrintable(QStringLiteral("only %1 distinct accents across 5 images x 4 bitmap sizes; the rescale path is likely inactive").arg(seen.size())));
}

QTEST_MAIN(TestQuantizerParity)
#include "tst_quantizer_parity.moc"
