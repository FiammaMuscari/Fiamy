#include "youtubedownloader.h"

#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QDebug>
#include <QRegularExpression>
#include <QCoreApplication>
#include <QFile>
#include <QDir>
#include <QStandardPaths>
#include <QUrl>
#include <QUrlQuery>
#include <QFileInfo>
#include <QTimer>
#include <QDataStream>
#include <QNetworkAccessManager>
#include <QNetworkRequest>
#include <QNetworkReply>
#include <QFileDevice>
#include <QSysInfo>

#ifdef __COSMOPOLITAN__
extern "C" {
#include <libc/dce.h>
}
#endif

static constexpr qint64 kMinValidAudioSize = 100000;
static constexpr quint32 kCacheIndexMagic = 0x4649414d; // FIAM
static constexpr quint16 kCacheIndexVersion = 2;

static QString appWritableDataDir()
{
    QString path = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    if (path.isEmpty()) {
        path = QDir::homePath() + "/.local/share/Fiamy";
    }
    QDir().mkpath(path);
    return path;
}

static QString downloadedYtDlpPath()
{
#ifdef __COSMOPOLITAN__
    return appWritableDataDir() + "/bin/" + (IsWindows() ? "yt-dlp.exe" : "yt-dlp");
#else
#ifdef Q_OS_WIN
    return QCoreApplication::applicationDirPath() + "/yt-dlp.exe";
#else
    return appWritableDataDir() + "/bin/yt-dlp";
#endif
#endif
}

static bool isExecutableFile(const QString &path)
{
    QFileInfo info(path);
    return info.exists() && info.isFile() && info.isExecutable();
}

static bool isPythonYtDlpWrapper(const QString &path)
{
    QFile file(path);
    if (!file.open(QIODevice::ReadOnly)) {
        return false;
    }

    const QByteArray header = file.read(512);
    return header.contains("from yt_dlp import main");
}

static bool isDownloadedYtDlpPath(const QString &path)
{
    return QFileInfo(path).absoluteFilePath()
        == QFileInfo(downloadedYtDlpPath()).absoluteFilePath();
}

static bool isRunningWindows()
{
#ifdef __COSMOPOLITAN__
    return IsWindows();
#elif defined(Q_OS_WIN)
    return true;
#else
    return false;
#endif
}

static void makeYtDlpExecutable(const QString &path)
{
    if (isRunningWindows()) {
        return;
    }

    QFile file(path);
    file.setPermissions(QFileDevice::ReadOwner | QFileDevice::WriteOwner | QFileDevice::ExeOwner
                        | QFileDevice::ReadGroup | QFileDevice::ExeGroup
                        | QFileDevice::ReadOther | QFileDevice::ExeOther);
}

static bool isRunningArm64()
{
    const QString arch = QSysInfo::currentCpuArchitecture().toLower();
    return arch == "arm64" || arch == "aarch64";
}

struct EmbeddedYtDlpPayload {
    const unsigned char *start = nullptr;
    const unsigned char *end = nullptr;
    const char *name = nullptr;

    qint64 size() const
    {
        return static_cast<qint64>(reinterpret_cast<quintptr>(end)
                                  - reinterpret_cast<quintptr>(start));
    }

    bool isValid() const
    {
        return start && end && size() > 0;
    }
};

#ifdef FIAMY_EMBEDDED_YT_DLP
extern "C" {
extern const unsigned char fiamy_embedded_ytdlp_linux_start[];
extern const unsigned char fiamy_embedded_ytdlp_linux_end[];
extern const unsigned char fiamy_embedded_ytdlp_linux_aarch64_start[];
extern const unsigned char fiamy_embedded_ytdlp_linux_aarch64_end[];
extern const unsigned char fiamy_embedded_ytdlp_macos_start[];
extern const unsigned char fiamy_embedded_ytdlp_macos_end[];
extern const unsigned char fiamy_embedded_ytdlp_windows_start[];
extern const unsigned char fiamy_embedded_ytdlp_windows_end[];
}
#endif

static EmbeddedYtDlpPayload embeddedYtDlpPayload()
{
#ifdef FIAMY_EMBEDDED_YT_DLP
#ifdef __COSMOPOLITAN__
    if (IsWindows()) {
        return {fiamy_embedded_ytdlp_windows_start, fiamy_embedded_ytdlp_windows_end, "yt-dlp.exe"};
    }
    if (IsXnu()) {
        return {fiamy_embedded_ytdlp_macos_start, fiamy_embedded_ytdlp_macos_end, "yt-dlp_macos"};
    }
    if (IsLinux()) {
        if (isRunningArm64()) {
            return {fiamy_embedded_ytdlp_linux_aarch64_start,
                    fiamy_embedded_ytdlp_linux_aarch64_end,
                    "yt-dlp_linux_aarch64"};
        }
        return {fiamy_embedded_ytdlp_linux_start, fiamy_embedded_ytdlp_linux_end, "yt-dlp_linux"};
    }
#elif defined(Q_OS_WIN)
    return {fiamy_embedded_ytdlp_windows_start, fiamy_embedded_ytdlp_windows_end, "yt-dlp.exe"};
#elif defined(Q_OS_MACOS)
    return {fiamy_embedded_ytdlp_macos_start, fiamy_embedded_ytdlp_macos_end, "yt-dlp_macos"};
#elif defined(Q_OS_LINUX)
    if (isRunningArm64()) {
        return {fiamy_embedded_ytdlp_linux_aarch64_start,
                fiamy_embedded_ytdlp_linux_aarch64_end,
                "yt-dlp_linux_aarch64"};
    }
    return {fiamy_embedded_ytdlp_linux_start, fiamy_embedded_ytdlp_linux_end, "yt-dlp_linux"};
#endif
#endif
    return {};
}

static bool extractEmbeddedYtDlp(QString *extractedPath)
{
#ifdef FIAMY_EMBEDDED_YT_DLP
    const EmbeddedYtDlpPayload payload = embeddedYtDlpPayload();
    if (!payload.isValid()) {
        return false;
    }
    const qint64 payloadSize = payload.size();

    const QString targetPath = downloadedYtDlpPath();
    QFileInfo targetInfo(targetPath);
    QDir().mkpath(targetInfo.absolutePath());

    if (isExecutableFile(targetPath) && QFileInfo(targetPath).size() == payloadSize) {
        if (extractedPath) {
            *extractedPath = targetPath;
        }
        return true;
    }

    const QString tempPath = targetPath + ".tmp";
    QFile::remove(tempPath);

    QFile output(tempPath);
    if (!output.open(QIODevice::WriteOnly)) {
        qWarning() << "⚠️ No se pudo extraer yt-dlp embebido:" << tempPath;
        return false;
    }
    const qint64 written = output.write(reinterpret_cast<const char *>(payload.start), payloadSize);
    output.close();
    if (written != payloadSize) {
        QFile::remove(tempPath);
        qWarning() << "⚠️ Escritura incompleta al extraer yt-dlp embebido:" << payload.name;
        return false;
    }
    makeYtDlpExecutable(tempPath);

    QFile::remove(targetPath);
    if (!QFile::rename(tempPath, targetPath)) {
        QFile::remove(tempPath);
        qWarning() << "⚠️ No se pudo instalar yt-dlp embebido:" << targetPath;
        return false;
    }
    makeYtDlpExecutable(targetPath);

    if (extractedPath) {
        *extractedPath = targetPath;
    }
    qDebug() << "✅ yt-dlp embebido extraído:" << targetPath << "(" << payload.name << ")";
    return true;
#else
    Q_UNUSED(extractedPath);
    return false;
#endif
}

static bool isEmbeddedYtDlpPath(const QString &path)
{
#ifdef FIAMY_EMBEDDED_YT_DLP
    return QFileInfo(path).absoluteFilePath()
        == QFileInfo(downloadedYtDlpPath()).absoluteFilePath();
#else
    Q_UNUSED(path);
    return false;
#endif
}

static QString bundledLinuxYtDlpPath()
{
#ifdef Q_OS_LINUX
    const QString appPath = QCoreApplication::applicationDirPath();
    const QStringList candidates = {
        appPath + "/yt-dlp",
        QDir(appPath).absoluteFilePath("../share/fiamy/yt-dlp"),
        "/usr/share/fiamy/yt-dlp"
    };

    for (const QString &candidate : candidates) {
        if (isExecutableFile(candidate) && !isPythonYtDlpWrapper(candidate)) {
            return QFileInfo(candidate).absoluteFilePath();
        }
    }
#endif
    return {};
}

static QString bundledMacYtDlpPath()
{
#ifdef Q_OS_MACOS
    const QString appPath = QCoreApplication::applicationDirPath();
    const QStringList candidates = {
        appPath + "/yt-dlp",
        QDir(appPath).absoluteFilePath("../Resources/yt-dlp")
    };

    for (const QString &candidate : candidates) {
        if (isExecutableFile(candidate) && !isPythonYtDlpWrapper(candidate)) {
            return QFileInfo(candidate).absoluteFilePath();
        }
    }
#endif
    return {};
}

static QString getYtDlpPath()
{
    QString embeddedPath;
    if (extractEmbeddedYtDlp(&embeddedPath)) {
        return embeddedPath;
    }

    const QString downloadedPath = downloadedYtDlpPath();
#ifdef __COSMOPOLITAN__
    return downloadedPath;
#endif

    const QString systemPath = QStandardPaths::findExecutable("yt-dlp");
    if (!systemPath.isEmpty()) {
        return systemPath;
    }

    if (QFileInfo::exists(downloadedPath)) {
        return downloadedPath;
    }

#ifdef Q_OS_WIN
    return downloadedPath;
#else
    const QString bundledPath = bundledLinuxYtDlpPath();
    if (!bundledPath.isEmpty()) {
        return bundledPath;
    }
    const QString bundledMacPath = bundledMacYtDlpPath();
    if (!bundledMacPath.isEmpty()) {
        return bundledMacPath;
    }
    return downloadedPath;
#endif
}

static QUrl ytDlpDownloadUrl()
{
#ifdef __COSMOPOLITAN__
    if (IsWindows()) {
        return QUrl("https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe");
    }
    if (IsXnu()) {
        return QUrl("https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp_macos");
    }
    if (IsLinux() && isRunningArm64()) {
        return QUrl("https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp_linux_aarch64");
    }
    return QUrl("https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp_linux");
#else
#ifdef Q_OS_WIN
    return QUrl("https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe");
#elif defined(Q_OS_MACOS)
    return QUrl("https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp_macos");
#else
    return QUrl("https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp_linux");
#endif
#endif
}

static QStringList playableAudioExtensions()
{
#ifdef __COSMOPOLITAN__
    if (IsXnu()) {
        return {"wav", "mp3", "flac"};
    }
    return {"m4a", "mp4", "mp3", "aac", "wav", "flac"};
#elif defined(Q_OS_MACOS)
    return {"mp4", "m4a", "mp3", "aac", "wav", "flac"};
#else
    return {"mp3", "m4a", "ogg", "opus", "flac", "wav", "webm"};
#endif
}

static QStringList convertibleAudioExtensions()
{
#ifdef __COSMOPOLITAN__
    if (IsXnu()) {
        return {"m4a", "mp4", "aac"};
    }
#endif
    return {};
}

static bool hasPlayableAudioExtension(const QString &filePath)
{
    const QString suffix = QFileInfo(filePath).suffix().toLower();
    return playableAudioExtensions().contains(suffix);
}

static bool isValidAudioFile(const QString &filePath)
{
    QFileInfo info(filePath);
    return info.exists() && info.isFile() && info.size() > kMinValidAudioSize
        && hasPlayableAudioExtension(filePath);
}

static QString playableFileUrl(const QString &filePath)
{
    return QUrl::fromLocalFile(QFileInfo(filePath).absoluteFilePath()).toString();
}

static QString findExistingAudioFile(const QString &videoId, const QStringList &extensions)
{
    const QDir cacheDir(appWritableDataDir() + "/cache/audio");
    for (const QString &extension : extensions) {
        const QString candidate = cacheDir.filePath(videoId + "." + extension);
        QFileInfo info(candidate);
        if (info.exists() && info.isFile() && info.size() > kMinValidAudioSize) {
            return candidate;
        }
    }
    return {};
}

static QString convertToPlayableAudioIfNeeded(const QString &filePath)
{
#ifdef __COSMOPOLITAN__
    if (!IsXnu() || filePath.isEmpty()) {
        return filePath;
    }

    const QFileInfo inputInfo(filePath);
    const QString suffix = inputInfo.suffix().toLower();
    if (!convertibleAudioExtensions().contains(suffix)) {
        return filePath;
    }

    const QString outputPath = inputInfo.dir().filePath(inputInfo.completeBaseName() + ".wav");
    if (isValidAudioFile(outputPath)) {
        return outputPath;
    }

    const QString afconvertPath = QStringLiteral("/usr/bin/afconvert");
    if (!isExecutableFile(afconvertPath)) {
        qWarning() << "⚠️ afconvert no disponible; no se puede convertir audio para APE/macOS";
        return {};
    }

    const QString tempPath = outputPath + ".tmp";
    QFile::remove(tempPath);

    QProcess converter;
    converter.setProgram(afconvertPath);
    converter.setArguments({ filePath, tempPath, "-f", "WAVE", "-d", "LEI16@44100" });
    converter.start();

    if (!converter.waitForFinished(120000) || converter.exitStatus() != QProcess::NormalExit
        || converter.exitCode() != 0) {
        qWarning() << "⚠️ afconvert falló:"
                   << QString::fromUtf8(converter.readAllStandardError()).trimmed();
        QFile::remove(tempPath);
        return {};
    }

    QFile::remove(outputPath);
    if (!QFile::rename(tempPath, outputPath)) {
        qWarning() << "⚠️ No se pudo mover WAV convertido a cache:" << outputPath;
        QFile::remove(tempPath);
        return {};
    }

    QFile::remove(filePath);
    qDebug() << "✅ Audio convertido para APE/macOS:" << outputPath;
    return outputPath;
#else
    return filePath;
#endif
}

/* ===================== CACHE SERIALIZATION ===================== */

QDataStream &operator<<(QDataStream &out, const CacheEntry &entry)
{
    out << entry.videoId << entry.filePath << entry.title << entry.author
        << entry.fileSize << entry.lastAccessed;
    return out;
}

QDataStream &operator>>(QDataStream &in, CacheEntry &entry)
{
    in >> entry.videoId >> entry.filePath >> entry.title >> entry.author
       >> entry.fileSize >> entry.lastAccessed;
    return in;
}

/* ===================== CONSTRUCTOR/DESTRUCTOR ===================== */

YoutubeDownloader::YoutubeDownloader(QObject *parent)
    : QObject(parent)
    , m_ytdlpPath(getYtDlpPath())
    , m_process(new QProcess(this))
    , m_currentDownloadProcess(nullptr)
    , m_maxCacheSize(500 * 1024 * 1024)
    , m_currentCacheSize(0)
    , m_maxFileSize(100 * 1024 * 1024)
    , m_maxSongsPerPlaylist(10)
    , m_ytdlpDownloadInProgress(false)
    , m_downloadedCount(0)
    , m_totalToDownload(0)
{
    connect(m_process, &QProcess::finished,
            this, &YoutubeDownloader::onProcessFinished);
    connect(m_process, &QProcess::errorOccurred,
            this, &YoutubeDownloader::onProcessError);
    connect(m_process, &QProcess::readyReadStandardError,
            this, &YoutubeDownloader::onReadyReadStandardError);

    if (!QFile::exists(m_ytdlpPath)) {
        QString embeddedPath;
        if (extractEmbeddedYtDlp(&embeddedPath)) {
            m_ytdlpPath = embeddedPath;
            qDebug() << "✅ yt-dlp embebido listo:" << m_ytdlpPath;
        } else {
            qDebug() << "⬇️ yt-dlp no encontrado; se descargará en el primer uso";
        }
    } else if (isEmbeddedYtDlpPath(m_ytdlpPath)) {
        qDebug() << "✅ yt-dlp embebido listo:" << m_ytdlpPath;
    } else if (isDownloadedYtDlpPath(m_ytdlpPath)) {
        qDebug() << "✅ yt-dlp app-managed encontrado";
    } else {
        qDebug() << "✅ yt-dlp del sistema o empaquetado encontrado:" << m_ytdlpPath;
    }

    ensureAudioCacheDir();
    loadCacheIndex();
    calculateCurrentCacheSize();

    if (m_currentCacheSize > m_maxCacheSize) {
        qDebug() << "🧹 Cache excedido al iniciar, limpiando entradas viejas";
        cleanOldestEntries(m_currentCacheSize - m_maxCacheSize);
        calculateCurrentCacheSize();
    }
}

YoutubeDownloader::~YoutubeDownloader()
{
    saveCacheIndex();

    if (m_process && m_process->state() != QProcess::NotRunning) {
        m_process->kill();
        m_process->waitForFinished();
    }

    if (m_currentDownloadProcess) {
        m_currentDownloadProcess->kill();
        m_currentDownloadProcess->waitForFinished(3000);
        m_currentDownloadProcess->deleteLater();
    }
}

/* ===================== YT-DLP AUTO-UPDATE ===================== */

void YoutubeDownloader::downloadYtDlp()
{
    if (m_ytdlpDownloadInProgress) {
        return;
    }

    QString embeddedPath;
    if (extractEmbeddedYtDlp(&embeddedPath)) {
        m_ytdlpPath = embeddedPath;
        qDebug() << "✅ yt-dlp embebido listo";
        emit ytdlpDownloading("✅ yt-dlp listo");
        if (!m_pendingYtDlpUrl.isEmpty()) {
            const QString pendingUrl = m_pendingYtDlpUrl;
            m_pendingYtDlpUrl.clear();
            QTimer::singleShot(0, this, [this, pendingUrl]() { getAudioUrl(pendingUrl); });
        }
        return;
    }

    if (!isDownloadedYtDlpPath(m_ytdlpPath)) {
        m_ytdlpPath = downloadedYtDlpPath();
    }

    m_ytdlpDownloadInProgress = true;
    emit ytdlpDownloading("Downloading yt-dlp...");
    emit downloadCountChanged(0, 1);
    emit downloadProgressChanged(1, 1, 0, "yt-dlp");
    emit progressUpdate("⬇️ Downloading yt-dlp...");

    QNetworkAccessManager *manager = new QNetworkAccessManager(this);
    QUrl url = ytDlpDownloadUrl();

    QNetworkRequest request(url);
    request.setRawHeader("User-Agent", "Fiamy/1.0");
    QNetworkReply *reply = manager->get(request);

    connect(reply, &QNetworkReply::downloadProgress, this,
            [this](qint64 received, qint64 total) {
                if (total > 0) {
                    int percent = (received * 100) / total;
                    emit ytdlpDownloading(QString("Downloading yt-dlp: %1%").arg(percent));
                    emit downloadProgressChanged(1, 1, percent, "yt-dlp");
                    emit progressUpdate(QString("⬇️ Downloading yt-dlp: %1%").arg(percent));
                    qDebug() << "⬇️ yt-dlp:" << percent << "%";
                }
            });

    connect(reply, &QNetworkReply::finished, this, [this, reply, manager]() {
        m_ytdlpDownloadInProgress = false;
        if (reply->error() == QNetworkReply::NoError) {
            QFileInfo targetInfo(m_ytdlpPath);
            QDir().mkpath(targetInfo.absolutePath());

            QFile file(m_ytdlpPath);

            if (file.open(QIODevice::WriteOnly)) {
                file.write(reply->readAll());
                file.close();
#ifndef Q_OS_WIN
                makeYtDlpExecutable(m_ytdlpPath);
#endif
                qDebug() << "✅ yt-dlp descargado correctamente";
                emit ytdlpDownloading("✅ yt-dlp listo");
                emit downloadProgressChanged(1, 1, 100, "yt-dlp");
                emit progressUpdate("✅ yt-dlp ready");
                if (!m_pendingYtDlpUrl.isEmpty()) {
                    const QString pendingUrl = m_pendingYtDlpUrl;
                    m_pendingYtDlpUrl.clear();
                    QTimer::singleShot(0, this, [this, pendingUrl]() { getAudioUrl(pendingUrl); });
                }
            } else {
                qCritical() << "❌ No se pudo guardar yt-dlp";
                m_pendingYtDlpUrl.clear();
                emit errorOccurred("No se pudo instalar yt-dlp");
            }
        } else {
            qCritical() << "❌ Error descargando yt-dlp:" << reply->errorString();
            m_pendingYtDlpUrl.clear();
            emit errorOccurred("Error descargando yt-dlp. Verifica tu conexión a internet.");
        }

        reply->deleteLater();
        manager->deleteLater();
    });
}

bool YoutubeDownloader::ensureYtDlpReadyForRequest(const QString &youtubeUrl)
{
    if (QFile::exists(m_ytdlpPath)) {
        return true;
    }

    QString embeddedPath;
    if (extractEmbeddedYtDlp(&embeddedPath)) {
        m_ytdlpPath = embeddedPath;
        return true;
    }

    m_ytdlpPath = downloadedYtDlpPath();
    m_pendingYtDlpUrl = youtubeUrl;
    qDebug() << "⬇️ yt-dlp no existe, iniciando descarga";
    downloadYtDlp();
    return false;
}

void YoutubeDownloader::checkYtDlpVersion()
{
    if (!isDownloadedYtDlpPath(m_ytdlpPath)) {
        qDebug() << "✅ yt-dlp externo/empaquetado, no se auto-actualiza desde Fiamy";
        return;
    }

    QString settingsPath = appWritableDataDir() + "/ytdlp_update.dat";
    QFile settingsFile(settingsPath);

    QDateTime lastCheck;
    if (settingsFile.open(QIODevice::ReadOnly)) {
        QDataStream in(&settingsFile);
        in >> lastCheck;
        settingsFile.close();
    }

    // Actualizar si pasaron más de 7 días
    if (!lastCheck.isValid() || lastCheck.daysTo(QDateTime::currentDateTime()) > 7) {
        qDebug() << "🔄 Actualizando yt-dlp (última actualización hace"
                 << (lastCheck.isValid() ? QString::number(lastCheck.daysTo(QDateTime::currentDateTime())) + " días" : "nunca") << ")";

        // Borrar versión vieja
        QFile::remove(m_ytdlpPath);

        // Descargar nueva
        downloadYtDlp();

        // Guardar fecha
        if (settingsFile.open(QIODevice::WriteOnly)) {
            QDataStream out(&settingsFile);
            out << QDateTime::currentDateTime();
            settingsFile.close();
        }
    } else {
        qDebug() << "✅ yt-dlp actualizado (última verificación hace"
                 << lastCheck.daysTo(QDateTime::currentDateTime()) << "días)";
    }
}

/* ===================== CACHE INDEX ===================== */

void YoutubeDownloader::loadCacheIndex()
{
    QString indexPath = ensureAudioCacheDir() + "/cache_index.dat";
    QFile file(indexPath);

    if (!file.open(QIODevice::ReadOnly)) {
        qDebug() << "📋 No hay índice previo";
        return;
    }

    QDataStream in(&file);
    quint32 magic = 0;
    in >> magic;

    qint64 count = 0;
    quint16 version = 1;
    const bool hasHeader = magic == kCacheIndexMagic;
    if (hasHeader) {
        qint32 storedCount = 0;
        in >> version >> storedCount;
        count = storedCount;
    } else {
        file.seek(0);
        in.setDevice(&file);
        qsizetype storedCount = 0;
        in >> storedCount;
        count = storedCount;
    }

    for (int i = 0; i < count; ++i) {
        QString key;
        CacheEntry entry;
        in >> key;
        if (hasHeader && version >= 2) {
            in >> entry;
        } else {
            in >> entry.videoId >> entry.filePath >> entry.fileSize >> entry.lastAccessed;
        }
        if (entry.title.isEmpty())
            entry.title = entry.videoId;
        m_cacheIndex[key] = entry;
    }

    file.close();
    qDebug() << "📋 Cargadas" << m_cacheIndex.size() << "entradas";
}

void YoutubeDownloader::saveCacheIndex()
{
    QString indexPath = ensureAudioCacheDir() + "/cache_index.dat";
    QFile file(indexPath);

    if (!file.open(QIODevice::WriteOnly)) {
        qWarning() << "⚠️ No se pudo guardar índice";
        return;
    }

    QDataStream out(&file);
    out << kCacheIndexMagic << kCacheIndexVersion << qint32(m_cacheIndex.size());

    for (auto it = m_cacheIndex.constBegin(); it != m_cacheIndex.constEnd(); ++it) {
        out << it.key() << it.value();
    }

    file.close();
}

void YoutubeDownloader::updateCacheEntry(const QString &videoId,
                                         const QString &filePath,
                                         qint64 size,
                                         const QString &title,
                                         const QString &author)
{
    const CacheEntry previous = m_cacheIndex.value(videoId);

    CacheEntry entry;
    entry.videoId = videoId;
    entry.filePath = filePath;
    entry.title = title.isEmpty() ? previous.title : title;
    entry.author = author.isEmpty() ? previous.author : author;
    entry.fileSize = size;
    entry.lastAccessed = QDateTime::currentDateTime();

    m_cacheIndex[videoId] = entry;
    saveCacheIndex();
}

/* ===================== HELPERS ===================== */

QString YoutubeDownloader::extractVideoId(const QString &url)
{
    static const QList<QRegularExpression> patterns = {
        QRegularExpression("v=([a-zA-Z0-9_-]{11})"),
        QRegularExpression("youtu\\.be/([a-zA-Z0-9_-]{11})"),
        QRegularExpression("^([a-zA-Z0-9_-]{11})$")
    };

    for (const auto &re : patterns) {
        auto m = re.match(url);
        if (m.hasMatch())
            return m.captured(1);
    }
    return {};
}

QString YoutubeDownloader::extractPlaylistId(const QString &url)
{
    QRegularExpression re("list=([a-zA-Z0-9_-]+)");
    auto m = re.match(url);
    return m.hasMatch() ? m.captured(1) : QString();
}

QString YoutubeDownloader::cleanUrlForPlaylist(const QString &url)
{
    QUrl qurl(url);
    QUrlQuery query(qurl);

    QUrlQuery clean;
    if (!query.queryItemValue("v").isEmpty())
        clean.addQueryItem("v", query.queryItemValue("v"));
    if (!query.queryItemValue("list").isEmpty())
        clean.addQueryItem("list", query.queryItemValue("list"));

    qurl.setQuery(clean);
    return qurl.toString();
}

QString YoutubeDownloader::ensureAudioCacheDir()
{
    QDir cacheDir(appWritableDataDir() + "/cache/audio");

    if (!cacheDir.exists()) {
        cacheDir.mkpath(".");
        qDebug() << "📁 Cache creado en:" << cacheDir.absolutePath();
    }

    return cacheDir.absolutePath();
}

QString YoutubeDownloader::findCachedAudioFile(const QString &videoId)
{
    if (videoId.isEmpty()) {
        return {};
    }

    if (m_cacheIndex.contains(videoId)) {
        const QString indexedPath = m_cacheIndex.value(videoId).filePath;
        if (isValidAudioFile(indexedPath)) {
            return indexedPath;
        }
    }

    const QDir cacheDir(ensureAudioCacheDir());
    for (const QString &extension : playableAudioExtensions()) {
        const QString candidate = cacheDir.filePath(videoId + "." + extension);
        if (isValidAudioFile(candidate)) {
            return candidate;
        }
    }

    const QString convertible = findExistingAudioFile(videoId, convertibleAudioExtensions());
    if (!convertible.isEmpty()) {
        const QString converted = convertToPlayableAudioIfNeeded(convertible);
        if (isValidAudioFile(converted)) {
            return converted;
        }
    }

    return {};
}

QString YoutubeDownloader::downloadOutputTemplate(const QString &videoId)
{
    return QDir(ensureAudioCacheDir()).filePath(videoId + ".%(ext)s");
}

bool YoutubeDownloader::shouldDownloadNativeAudio() const
{
#if defined(__COSMOPOLITAN__) || defined(Q_OS_MACOS)
    return true;
#else
    return QStandardPaths::findExecutable("ffmpeg").isEmpty();
#endif
}

bool YoutubeDownloader::isPlaylistUrl(const QString &url)
{
    return !extractPlaylistId(url).isEmpty();
}

void YoutubeDownloader::calculateCurrentCacheSize()
{
    m_currentCacheSize = 0;
    bool removedMissingEntries = false;

    for (auto it = m_cacheIndex.begin(); it != m_cacheIndex.end();) {
        if (isValidAudioFile(it->filePath)) {
            m_currentCacheSize += it->fileSize;
            ++it;
        } else {
            qDebug() << "🔍 Faltante:" << it->videoId;
            it = m_cacheIndex.erase(it);
            removedMissingEntries = true;
        }
    }

    if (removedMissingEntries)
        saveCacheIndex();

    qDebug() << "💾 Cache:"
             << QString::number(m_currentCacheSize / 1024.0 / 1024.0, 'f', 1) << "MB /"
             << QString::number(m_maxCacheSize / 1024.0 / 1024.0, 'f', 1) << "MB";
}

void YoutubeDownloader::cleanOldestEntries(qint64 bytesNeeded)
{
    QList<CacheEntry> entries = m_cacheIndex.values();
    std::sort(entries.begin(), entries.end(),
              [](const CacheEntry &a, const CacheEntry &b) {
                  return a.lastAccessed < b.lastAccessed;
              });

    qint64 freedBytes = 0;

    for (int i = 0; i < entries.size(); ++i) {
        const CacheEntry &entry = entries.at(i);
        if (freedBytes >= bytesNeeded) break;

        if (QFile::remove(entry.filePath)) {
            qDebug() << "🗑️ LRU:" << entry.videoId;
            freedBytes += entry.fileSize;
            m_currentCacheSize -= entry.fileSize;
            m_cacheIndex.remove(entry.videoId);
        }
    }

    saveCacheIndex();
}

bool YoutubeDownloader::makeSpaceForFile(qint64 estimatedSize)
{
    if (estimatedSize > m_maxFileSize) {
        emit errorOccurred("Canción muy larga");
        return false;
    }

    if ((m_currentCacheSize + estimatedSize) <= m_maxCacheSize) {
        return true;
    }

    qint64 toFree = (m_currentCacheSize + estimatedSize) - m_maxCacheSize;
    toFree = qMax(toFree, estimatedSize);

    cleanOldestEntries(toFree);
    return true;
}

/* ===================== PUBLIC ===================== */

void YoutubeDownloader::getAudioUrl(const QString &youtubeUrl)
{
    if (!ensureYtDlpReadyForRequest(youtubeUrl))
        return;

    m_downloadQueue.clear();
    m_downloadedCount = 0;
    m_totalToDownload = 0;
    m_currentUrl = youtubeUrl;
    m_isPlaylist = isPlaylistUrl(youtubeUrl);

    QString videoId = extractVideoId(youtubeUrl);

    // ✅ Para URLs individuales: verificar cache y reproducir inmediatamente
    if (!m_isPlaylist && !videoId.isEmpty()) {
        const QString filePath = findCachedAudioFile(videoId);
        if (!filePath.isEmpty()) {
            if (m_cacheIndex.contains(videoId)) {
                m_cacheIndex[videoId].lastAccessed = QDateTime::currentDateTime();
                saveCacheIndex();
            } else {
                updateCacheEntry(videoId, filePath, QFileInfo(filePath).size());
            }

            const CacheEntry entry = m_cacheIndex.value(videoId);
            const bool hasMetadata = !entry.title.isEmpty() && entry.title != videoId;
            if (hasMetadata) {
                qDebug() << "⚡ CACHE HIT - Reproducción instantánea";

                emit audioReady(playableFileUrl(filePath), entry.title,
                                entry.author.isEmpty() ? "Cached" : entry.author);
                return;
            }

            qDebug() << "⚡ CACHE HIT sin metadata; actualizando título";
        } else if (m_cacheIndex.contains(videoId)) {
            QFile::remove(m_cacheIndex[videoId].filePath);
            m_cacheIndex.remove(videoId);
            saveCacheIndex();
            qDebug() << "🗑️ Cache corrupto eliminado";
        }
    }

    emit progressUpdate("🔍 Analyzing...");

    QStringList args;

    if (m_isPlaylist) {
        args << "-J"
             << "--yes-playlist"
             << "--flat-playlist"
             << "--playlist-end" << QString::number(m_maxSongsPerPlaylist)
             << "--quiet"
             << cleanUrlForPlaylist(youtubeUrl);
    } else {
        args << "-J"
             << "-f" << "bestaudio/best"
             << "--no-playlist"
             << "--quiet"
             << youtubeUrl;
    }

    qDebug() << "🔍 Ejecutando yt-dlp con args:" << args;
    m_process->start(m_ytdlpPath, args);
}

void YoutubeDownloader::cancelDownload()
{
    qDebug() << "❌ Cancelando descargas de la cola...";

    m_downloadedCount = 0;
    m_totalToDownload = 0;

    if (m_currentDownloadProcess) {
        disconnect(m_currentDownloadProcess, nullptr, this, nullptr);
        m_currentDownloadProcess->kill();

        if (!m_currentDownloadProcess->waitForFinished(3000)) {
            qWarning() << "⚠️ Proceso no terminó, forzando cierre";
            m_currentDownloadProcess->terminate();
            m_currentDownloadProcess->waitForFinished(1000);
        }

        m_currentDownloadProcess->deleteLater();
        m_currentDownloadProcess = nullptr;

        qDebug() << "✅ Proceso de descarga cancelado correctamente";
    }

    m_downloadQueue.clear();

    emit downloadCountChanged(0, 0);
    emit downloadProgressChanged(0, 0, 0, QString());
    emit progressUpdate("❌ Cancelled");

    qDebug() << "✅ Cancelación completa";
}

void YoutubeDownloader::clearCache()
{
    QDir dir(ensureAudioCacheDir());
    QStringList filters;
    const QStringList extensions = playableAudioExtensions() + convertibleAudioExtensions();
    for (const QString &extension : extensions) {
        filters << "*." + extension;
    }
    filters << "*.webm";

    for (const QFileInfo &fi : dir.entryInfoList(filters, QDir::Files)) {
        QFile::remove(fi.absoluteFilePath());
    }

    m_cacheIndex.clear();
    m_currentCacheSize = 0;
    saveCacheIndex();

    qDebug() << "🧹 Cache limpiado";
}

void YoutubeDownloader::removeFromCache(const QString &videoId)
{
    if (!m_cacheIndex.contains(videoId))
        return;

    CacheEntry entry = m_cacheIndex[videoId];

    if (QFile::remove(entry.filePath)) {
        m_currentCacheSize -= entry.fileSize;
        m_cacheIndex.remove(videoId);
        saveCacheIndex();
    }
}

/* ===================== DOWNLOAD ===================== */

void YoutubeDownloader::startNextDownload()
{
    if (m_downloadQueue.isEmpty()) {
        m_downloadedCount = 0;
        m_totalToDownload = 0;
        emit downloadCountChanged(0, 0);
        emit downloadProgressChanged(0, 0, 0, QString());
        return;
    }

    if (m_currentDownloadProcess)
        return;

    DownloadTask task = m_downloadQueue.dequeue();
    QString filePath = findCachedAudioFile(task.videoId);

    // ✅ Si ya está en cache, emitir inmediatamente y continuar
    if (!filePath.isEmpty()) {
        qDebug() << "♻️ Ya en cache, saltando:" << task.title;
        if (m_cacheIndex.contains(task.videoId)) {
            m_cacheIndex[task.videoId].lastAccessed = QDateTime::currentDateTime();
            if (m_cacheIndex[task.videoId].title.isEmpty()
                || m_cacheIndex[task.videoId].title == task.videoId) {
                m_cacheIndex[task.videoId].title = task.title;
            }
            if (m_cacheIndex[task.videoId].author.isEmpty())
                m_cacheIndex[task.videoId].author = task.author;
            saveCacheIndex();
        } else {
            updateCacheEntry(task.videoId, filePath, QFileInfo(filePath).size(),
                             task.title, task.author);
        }

        m_downloadedCount++;
        emit downloadProgressChanged(m_downloadedCount, m_totalToDownload, 100, task.title);
        emit downloadCountChanged(m_downloadedCount, m_totalToDownload);
        emit audioReady(playableFileUrl(filePath), task.title, task.author.isEmpty() ? "Cached" : task.author);

        QTimer::singleShot(100, this, &YoutubeDownloader::startNextDownload);
        return;
    }

    qint64 estimatedSize = 10 * 1024 * 1024;

    if (!makeSpaceForFile(estimatedSize)) {
        m_downloadedCount++;
        emit downloadProgressChanged(m_downloadedCount, m_totalToDownload, 100, task.title);
        emit downloadCountChanged(m_downloadedCount, m_totalToDownload);
        QTimer::singleShot(0, this, &YoutubeDownloader::startNextDownload);
        return;
    }

    const QString outputTemplate = downloadOutputTemplate(task.videoId);
    const bool nativeAudio = shouldDownloadNativeAudio();

    QStringList args;
    args << "-f";
    if (nativeAudio) {
        args << "bestaudio[ext=m4a]/bestaudio[acodec^=mp4a]/18/best[ext=mp4]";
    } else {
        args << "bestaudio/best"
             << "-x"
             << "--audio-format" << "mp3"
             << "--audio-quality" << "5";
    }
    args << "--no-playlist"
         << "--newline"
         << "-o" << outputTemplate
         << task.videoUrl;

    qDebug() << "================================================";
    qDebug() << "🎯 INICIANDO DESCARGA";
    qDebug() << "   Video ID:" << task.videoId;
    qDebug() << "   Título:" << task.title;
    qDebug() << "   URL:" << task.videoUrl;
    qDebug() << "   Destino:" << outputTemplate;
    qDebug() << "   Args:" << args.join(" ");
    qDebug() << "================================================";

    m_currentTask = task;
    m_currentDownloadProcess = new QProcess(this);

    connect(m_currentDownloadProcess,
            QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished),
            this, &YoutubeDownloader::onDownloadFinished);

    connect(m_currentDownloadProcess, &QProcess::readyReadStandardOutput,
            this, &YoutubeDownloader::onDownloadProgress);

    connect(m_currentDownloadProcess, &QProcess::readyReadStandardError,
            this, &YoutubeDownloader::onDownloadStderr);

    qDebug() << "⬇️ Descargando:" << task.title;
    emit progressUpdate(QString("⬇️ %1/%2 - %3")
                            .arg(m_downloadedCount + 1)
                            .arg(m_totalToDownload)
                            .arg(task.title));
    emit downloadProgressChanged(m_downloadedCount + 1, m_totalToDownload, 0, task.title);

    m_currentDownloadProcess->start(m_ytdlpPath, args);
}

void YoutubeDownloader::onDownloadFinished(int exitCode,
                                           QProcess::ExitStatus status)
{
    QString filePath = findCachedAudioFile(m_currentTask.videoId);
    if (filePath.isEmpty()) {
        const QString downloaded = findExistingAudioFile(
                m_currentTask.videoId, playableAudioExtensions() + convertibleAudioExtensions());
        filePath = convertToPlayableAudioIfNeeded(downloaded);
    }

    qDebug() << "================================================";
    qDebug() << "📊 RESULTADO DE DESCARGA:";
    qDebug() << "   Video ID:" << m_currentTask.videoId;
    qDebug() << "   Título:" << m_currentTask.title;
    qDebug() << "   Exit Code:" << exitCode;
    qDebug() << "   Status:" << (status == QProcess::NormalExit ? "Normal" : "Crashed");
    qDebug() << "   Archivo detectado:" << filePath;
    qDebug() << "   Archivo existe:" << (!filePath.isEmpty() && QFile::exists(filePath));

    if (!filePath.isEmpty() && QFile::exists(filePath)) {
        QFileInfo fi(filePath);
        qDebug() << "   Tamaño archivo:" << fi.size() << "bytes ("
                 << QString::number(fi.size() / 1024.0 / 1024.0, 'f', 2) << "MB)";
    }

    QString stderr_output = QString::fromUtf8(m_currentDownloadProcess->readAllStandardError());
    QString stdout_output = QString::fromUtf8(m_currentDownloadProcess->readAllStandardOutput());

    if (!stderr_output.isEmpty()) {
        qDebug() << "   === STDERR ===";
        qDebug().noquote() << stderr_output;
        qDebug() << "   ==============";
    }
    if (!stdout_output.isEmpty()) {
        qDebug() << "   === STDOUT ===";
        qDebug().noquote() << stdout_output;
        qDebug() << "   ==============";
    }
    qDebug() << "================================================";

    if (status == QProcess::NormalExit && exitCode == 0 && !filePath.isEmpty() && QFile::exists(filePath)) {
        QFileInfo fi(filePath);
        qint64 fileSize = fi.size();

        if (fileSize > m_maxFileSize) {
            QFile::remove(filePath);
            qDebug() << "❌ Muy grande, eliminado";
            m_downloadedCount++;
            emit downloadProgressChanged(m_downloadedCount, m_totalToDownload, 100, m_currentTask.title);
            emit downloadCountChanged(m_downloadedCount, m_totalToDownload);
        } else if (fileSize < kMinValidAudioSize) {
            QFile::remove(filePath);
            qDebug() << "❌ Descarga incompleta o corrupta (tamaño:" << fileSize << "bytes)";
            m_downloadedCount++;
            emit downloadProgressChanged(m_downloadedCount, m_totalToDownload, 100, m_currentTask.title);
            emit downloadCountChanged(m_downloadedCount, m_totalToDownload);
        } else {
            m_currentCacheSize += fileSize;
            updateCacheEntry(m_currentTask.videoId, filePath, fileSize,
                             m_currentTask.title, m_currentTask.author);

            qDebug() << "✅ Descarga completa:" << QString::number(fileSize / 1024.0 / 1024.0, 'f', 1) << "MB";

            m_downloadedCount++;
            emit downloadProgressChanged(m_downloadedCount, m_totalToDownload, 100, m_currentTask.title);
            emit downloadCountChanged(m_downloadedCount, m_totalToDownload);

            if (m_currentTask.emitWhenReady) {
                emit audioReady(playableFileUrl(filePath), m_currentTask.title,
                                m_currentTask.author.isEmpty() ? "Desconocido" : m_currentTask.author);
            }
        }
    } else {
        qWarning() << "⚠️ FALLÓ DESCARGA";
        qWarning() << "   Razón: Exit code" << exitCode << "| Status"
                   << (status == QProcess::NormalExit ? "Normal" : "Crashed");
        qWarning() << "   Archivo generado:" << (!filePath.isEmpty() && QFile::exists(filePath));

        m_downloadedCount++;
        emit downloadProgressChanged(m_downloadedCount, m_totalToDownload, 100, m_currentTask.title);
        emit downloadCountChanged(m_downloadedCount, m_totalToDownload);
    }

    m_currentDownloadProcess->deleteLater();
    m_currentDownloadProcess = nullptr;

    QTimer::singleShot(100, this, &YoutubeDownloader::startNextDownload);
}

/* ===================== METADATA ===================== */

void YoutubeDownloader::onProcessFinished(int exitCode,
                                          QProcess::ExitStatus status)
{
    if (status != QProcess::NormalExit || exitCode != 0) {
        QString stderr_output = QString::fromUtf8(m_process->readAllStandardError());
        qCritical() << "❌ Error obteniendo metadata";
        qCritical() << "   Exit code:" << exitCode;
        qCritical() << "   STDERR:" << stderr_output;
        emit errorOccurred("Error obteniendo info");
        return;
    }

    QString output = QString::fromUtf8(m_process->readAllStandardOutput()).trimmed();
    QJsonDocument doc = QJsonDocument::fromJson(output.toUtf8());

    if (!doc.isObject()) {
        qCritical() << "❌ Respuesta JSON inválida";
        qCritical() << "   Output:" << output.left(500);
        emit errorOccurred("Respuesta inválida");
        return;
    }

    QJsonObject obj = doc.object();

    if (m_isPlaylist && obj.contains("entries")) {
        QJsonArray entries = obj["entries"].toArray();

        int maxToAdd = qMin(entries.size(), m_maxSongsPerPlaylist);

        int alreadyCached = 0;
        int needsDownload = 0;

        for (int i = 0; i < maxToAdd; ++i) {
            QJsonObject e = entries[i].toObject();
            QString videoId = e["id"].toString();
            QString title = e["title"].toString();
            QString author = e["uploader"].toString().isEmpty() ? "YouTube" : e["uploader"].toString();

            DownloadTask t;
            t.videoId = videoId;
            t.title = title;
            t.author = author;
            t.videoUrl = "https://www.youtube.com/watch?v=" + videoId;
            t.emitWhenReady = true;

            m_downloadQueue.enqueue(t);

            if (!findCachedAudioFile(videoId).isEmpty()) {
                alreadyCached++;
            } else {
                needsDownload++;
            }
        }

        m_totalToDownload = maxToAdd;
        m_downloadedCount = 0;

        if (alreadyCached > 0) {
            qDebug() << "📋" << maxToAdd << "canciones (" << alreadyCached << "en cache," << needsDownload << "nuevas)";
            emit progressUpdate(QString("📋 %1 songs (%2 cached)").arg(maxToAdd).arg(alreadyCached));
        } else {
            qDebug() << "📋" << maxToAdd << "canciones encontradas";
            emit progressUpdate(QString("📋 %1 canciones encontradas").arg(maxToAdd));
        }

        emit downloadCountChanged(0, maxToAdd);

        startNextDownload();
    } else {
        QString videoId = obj["id"].toString();
        QString title = obj["title"].toString();
        QString author = obj["uploader"].toString();

        qDebug() << "🎵" << title;
        qDebug() << "👤" << author;

        m_totalToDownload = 1;
        m_downloadedCount = 0;

        DownloadTask t;
        t.videoId = videoId;
        t.title = title;
        t.author = author;
        t.videoUrl = m_currentUrl;
        t.emitWhenReady = true;
        m_downloadQueue.enqueue(t);

        startNextDownload();
    }
}

void YoutubeDownloader::onProcessError(QProcess::ProcessError error)
{
    QString errorStr;
    switch(error) {
    case QProcess::FailedToStart: {
        QString embeddedPath;
        if (extractEmbeddedYtDlp(&embeddedPath)) {
            m_ytdlpPath = embeddedPath;
            errorStr = "yt-dlp no pudo iniciar; binario embebido reinstalado";
        } else {
            errorStr = "yt-dlp no pudo iniciar. Descargando...";
            downloadYtDlp();
        }
        break;
    }
    case QProcess::Crashed:
        errorStr = "yt-dlp se cerró inesperadamente";
        break;
    default:
        errorStr = "Error desconocido ejecutando yt-dlp";
    }

    qCritical() << "❌" << errorStr;
    emit errorOccurred(errorStr);
}

void YoutubeDownloader::onReadyReadStandardError()
{
    QString stderr_output = QString::fromUtf8(m_process->readAllStandardError());
    if (!stderr_output.trimmed().isEmpty()) {
        qWarning() << "⚠️ yt-dlp stderr (metadata):" << stderr_output;
    }
}

void YoutubeDownloader::onDownloadProgress()
{
    if (!m_currentDownloadProcess) return;

    QString output = QString::fromUtf8(m_currentDownloadProcess->readAllStandardOutput());

    QRegularExpression re("\\[download\\]\\s+(\\d+(?:\\.\\d+)?)%");
    auto matches = re.globalMatch(output);

    QRegularExpressionMatch match;
    while (matches.hasNext()) {
        match = matches.next();
    }

    if (match.hasMatch()) {
        QString percent = match.captured(1);
        bool ok = false;
        const double percentValue = percent.toDouble(&ok);
        emit progressUpdate(QStringLiteral("⬇️ %1/%2 - %3% - %4").arg(
            QString::number(m_downloadedCount + 1),
            QString::number(m_totalToDownload),
            percent,
            m_currentTask.title));
        emit downloadProgressChanged(m_downloadedCount + 1,
                                     m_totalToDownload,
                                     ok ? percentValue : 0,
                                     m_currentTask.title);
    }
}

void YoutubeDownloader::onDownloadStderr()
{
    if (!m_currentDownloadProcess) return;

    QString stderr_output = QString::fromUtf8(m_currentDownloadProcess->readAllStandardError());
    if (!stderr_output.trimmed().isEmpty()) {
        qWarning() << "⚠️ yt-dlp stderr (download):" << stderr_output;
    }
}
