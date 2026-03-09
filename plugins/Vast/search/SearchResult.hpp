#pragma once

#include <QObject>
#include <QQmlEngine>
#include <QString>
#include <QVariantList>
#include <QVariantMap>

// ---------------------------------------------------------------------------
// SearchResult
//
// A single search hit returned by SearchEngine. QML sees it as a plain
// property object; C++ callers build instances via the static factories.
//
// App:   type="app",  data keys: id, exec, terminal, categories
// File:  type="file", data keys: path, isDir, mimeType
// ---------------------------------------------------------------------------
class SearchResult : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("Created by SearchEngine")

    Q_PROPERTY(QString type READ type CONSTANT)
    Q_PROPERTY(QString title READ title CONSTANT)
    Q_PROPERTY(QString subtitle READ subtitle CONSTANT)
    Q_PROPERTY(QString icon READ icon CONSTANT)
    Q_PROPERTY(double score READ score CONSTANT)
    Q_PROPERTY(QVariantMap data READ data CONSTANT)
    Q_PROPERTY(QVariantList highlightRanges READ highlightRanges CONSTANT)

  public:
    explicit SearchResult(QObject* parent = nullptr) : QObject(parent) {}

    void setType(const QString& v) {
        m_type = v;
    }
    void setTitle(const QString& v) {
        m_title = v;
    }
    void setSubtitle(const QString& v) {
        m_subtitle = v;
    }
    void setIcon(const QString& v) {
        m_icon = v;
    }
    void setScore(double v) {
        m_score = v;
    }
    void setData(const QVariantMap& v) {
        m_data = v;
    }
    void setHighlightRanges(const QVariantList& v) {
        m_highlightRanges = v;
    }

    static SearchResult* makeFile(const QString& title, const QString& subtitle, const QString& icon, double score, const QVariantMap& data, const QVariantList& ranges,
                                  QObject* parent = nullptr);

    QString              type() const {
        return m_type;
    }
    QString title() const {
        return m_title;
    }
    QString subtitle() const {
        return m_subtitle;
    }
    QString icon() const {
        return m_icon;
    }
    double score() const {
        return m_score;
    }
    QVariantMap data() const {
        return m_data;
    }
    QVariantList highlightRanges() const {
        return m_highlightRanges;
    }

    // Returns HTML-highlighted title using pre-computed ranges.
    Q_INVOKABLE QString highlightedTitle(const QString& color) const;

  private:
    QString      m_type;
    QString      m_title;
    QString      m_subtitle;
    QString      m_icon;
    double       m_score = 0.0;
    QVariantMap  m_data;
    QVariantList m_highlightRanges;
};
