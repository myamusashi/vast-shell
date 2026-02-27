#ifndef TRANSLATIONMANAGER_H
#define TRANSLATIONMANAGER_H

#include <QGuiApplication>
#include <QObject>
#include <QQmlEngine>
#include <QTranslator>

class TranslationManager : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString currentLanguage READ currentLanguage WRITE setCurrentLanguage NOTIFY languageChanged)
    QML_ELEMENT
    QML_SINGLETON

  public:
    static constexpr auto DefaultTranslationPath = ":/translations";

    explicit TranslationManager(QObject* parent = nullptr);

    QString                 currentLanguage() const;
    void                    setCurrentLanguage(const QString& language);

    Q_INVOKABLE bool        loadTranslation(const QString& language, const QString& translationPath = DefaultTranslationPath);
    Q_INVOKABLE QStringList availableLanguages() const;

  signals:
    void languageChanged();

  private:
    QTranslator       m_translator;
    QString           m_currentLanguage;
    const QStringList m_availableLanguages;
};

#endif // TRANSLATIONMANAGER_H
