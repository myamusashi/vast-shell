#include "TranslationManager.h"
#include <QDir>
#include <QDebug>

TranslationManager::TranslationManager(QObject *parent)
    : QObject(parent)
    , m_translator(new QTranslator(this))
    , m_currentLanguage("en")
{
    m_availableLanguages << "en" << "id";
}

TranslationManager::~TranslationManager()
{
    if (m_translator) {
        QGuiApplication::removeTranslator(m_translator);
    }
}

QString TranslationManager::currentLanguage() const
{
    return m_currentLanguage;
}

void TranslationManager::setCurrentLanguage(const QString &language)
{
    if (m_currentLanguage != language) {
        loadTranslation(language);
    }
}

bool TranslationManager::loadTranslation(const QString &language, const QString &translationPath)
{
    // Remove old translator
    if (m_translator) {
        QGuiApplication::removeTranslator(m_translator);
        delete m_translator;
        m_translator = new QTranslator(this);
    }

    // Construct translation file name
    QString fileName = QString("app_%1.qm").arg(language);
    QString fullPath = translationPath + "/" + fileName;

    qDebug() << "Loading translation:" << fullPath;

    // Load translation
    if (m_translator->load(fullPath)) {
        QGuiApplication::installTranslator(m_translator);
        m_currentLanguage = language;
        emit languageChanged();
        
        qDebug() << "Translation loaded successfully:" << language;
        return true;
    } else {
        qWarning() << "Failed to load translation:" << fullPath;
        return false;
    }
}

QStringList TranslationManager::availableLanguages() const
{
    return m_availableLanguages;
}
