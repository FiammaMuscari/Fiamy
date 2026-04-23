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

static QString getYtDlpPath() {
    QString appPath = QCoreApplication::applicationDirPath();
    return appPath + "/yt-dlp.exe";
}

/* ===================== CACHE SERIALIZATION ===================== */

QDataStream &operator<<(QDataStream &out, const CacheEntry &entry)
{
    out << entry.videoId << entry.filePath << entry.fileSize << entry.lastAccessed;
    return out;
}

QDataStream &operator>>(QDataStream &in, CacheEntry &entry)
{
    in >> entry.videoId >> entry.filePath >> entry.fileSize >> entry.lastAccessed;
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
    , m_downloadedCount(0)
    , m_totalToDownload(0)
{
    connect(m_process, &QProcess::finished,
            this, &YoutubeDownloader::onProcessFinished);
    connect(m_process, &QProcess::errorOccurred,
            this, &YoutubeDownloader::onProcessError);
    connect(m_process, &QProcess::readyReadStandardError,
            this, &YoutubeDownloader::onReadyReadStandardError);

    // Verificar/descargar yt-dlp al iniciar
    if (!QFile::exists(m_ytdlpPath)) {
        qDebug() << "⬇️ yt-dlp no encontrado, descargando...";
        downloadYtDlp();
    } else {
        qDebug() << "✅ yt-dlp encontrado";
        checkYtDlpVersion();
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
    emit ytdlpDownloading("Descargando yt-dlp...");

    QNetworkAccessManager *manager = new QNetworkAccessManager(this);
    QUrl url("https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe");

    QNetworkRequest request(url);
    request.setRawHeader("User-Agent", "Fiamy/1.0");
    QNetworkReply *reply = manager->get(request);

    connect(reply, &QNetworkReply::downloadProgress, this,
            [this](qint64 received, qint64 total) {
                if (total > 0) {
                    int percent = (received * 100) / total;
                    emit ytdlpDownloading(QString("Descargando yt-dlp: %1%").arg(percent));
                    qDebug() << "⬇️ yt-dlp:" << percent << "%";
                }
            });

    connect(reply, &QNetworkReply::finished, this, [this, reply, manager]() {
        if (reply->error() == QNetworkReply::NoError) {
            QFile file(m_ytdlpPath);

            if (file.open(QIODevice::WriteOnly)) {
                file.write(reply->readAll());
                file.close();
                qDebug() << "✅ yt-dlp descargado correctamente";
                emit ytdlpDownloading("✅ yt-dlp listo");
            } else {
                qCritical() << "❌ No se pudo guardar yt-dlp";
                emit errorOccurred("No se pudo instalar yt-dlp");
            }
        } else {
            qCritical() << "❌ Error descargando yt-dlp:" << reply->errorString();
            emit errorOccurred("Error descargando yt-dlp. Verifica tu conexión a internet.");
        }

        reply->deleteLater();
        manager->deleteLater();
    });
}

void YoutubeDownloader::checkYtDlpVersion()
{
    QString settingsPath = QCoreApplication::applicationDirPath() + "/ytdlp_update.dat";
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
    int count;
    in >> count;

    for (int i = 0; i < count; ++i) {
        QString key;
        CacheEntry entry;
        in >> key >> entry;
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
    out << m_cacheIndex.size();

    for (auto it = m_cacheIndex.constBegin(); it != m_cacheIndex.constEnd(); ++it) {
        out << it.key() << it.value();
    }

    file.close();
}

void YoutubeDownloader::updateCacheEntry(const QString &videoId,
                                         const QString &filePath,
                                         qint64 size)
{
    CacheEntry entry;
    entry.videoId = videoId;
    entry.filePath = filePath;
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
    QString projectDir = QCoreApplication::applicationDirPath();
    QDir cacheDir(projectDir + "/cache/audio");

    if (!cacheDir.exists()) {
        cacheDir.mkpath(".");
        qDebug() << "📁 Cache creado en:" << cacheDir.absolutePath();
    }

    return cacheDir.absolutePath();
}

bool YoutubeDownloader::isPlaylistUrl(const QString &url)
{
    return !extractPlaylistId(url).isEmpty();
}

void YoutubeDownloader::calculateCurrentCacheSize()
{
    m_currentCacheSize = 0;

    for (auto it = m_cacheIndex.begin(); it != m_cacheIndex.end(); ++it) {
        if (QFile::exists(it->filePath)) {
            m_currentCacheSize += it->fileSize;
        } else {
            qDebug() << "🔍 Faltante:" << it->videoId;
            it = m_cacheIndex.erase(it);
            --it;
        }
    }

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
    if (!QFile::exists(m_ytdlpPath)) {
        emit errorOccurred("yt-dlp no encontrado. Descargando...");
        qCritical() << "❌ yt-dlp.exe NO EXISTE, iniciando descarga";
        downloadYtDlp();
        return;
    }

    m_downloadQueue.clear();
    m_downloadedCount = 0;
    m_totalToDownload = 0;
    m_currentUrl = youtubeUrl;
    m_isPlaylist = isPlaylistUrl(youtubeUrl);

    QString videoId = extractVideoId(youtubeUrl);

    // ✅ Para URLs individuales: verificar cache y reproducir inmediatamente
    if (!videoId.isEmpty() && m_cacheIndex.contains(videoId)) {
        QString filePath = m_cacheIndex[videoId].filePath;
        if (QFile::exists(filePath)) {
            QFileInfo fi(filePath);
            if (fi.size() > 100000) {
                m_cacheIndex[videoId].lastAccessed = QDateTime::currentDateTime();
                saveCacheIndex();

                qDebug() << "⚡ CACHE HIT - Reproducción instantánea";

                QString title = m_cacheIndex[videoId].videoId;

                emit audioReady(filePath, title, "Cached");
                return;
            } else {
                QFile::remove(filePath);
                m_cacheIndex.remove(videoId);
                saveCacheIndex();
                qDebug() << "🗑️ Cache corrupto eliminado";
            }
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
    emit progressUpdate("❌ Cancelled");

    qDebug() << "✅ Cancelación completa";
}

void YoutubeDownloader::clearCache()
{
    QDir dir(ensureAudioCacheDir());
    for (const QFileInfo &fi : dir.entryInfoList(QStringList() << "*.mp3")) {
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
        return;
    }

    if (m_currentDownloadProcess)
        return;

    DownloadTask task = m_downloadQueue.dequeue();
    QString filePath = ensureAudioCacheDir() + "/" + task.videoId + ".mp3";

    // ✅ Si ya está en cache, emitir inmediatamente y continuar
    if (m_cacheIndex.contains(task.videoId) && QFile::exists(filePath)) {
        QFileInfo fi(filePath);
        if (fi.size() > 100000) {
            qDebug() << "♻️ Ya en cache, saltando:" << task.title;

            m_downloadedCount++;
            emit downloadCountChanged(m_downloadedCount, m_totalToDownload);
            emit audioReady(filePath, task.title, task.author.isEmpty() ? "Cached" : task.author);

            QTimer::singleShot(100, this, &YoutubeDownloader::startNextDownload);
            return;
        }
    }

    qint64 estimatedSize = 10 * 1024 * 1024;

    if (!makeSpaceForFile(estimatedSize)) {
        m_downloadedCount++;
        emit downloadCountChanged(m_downloadedCount, m_totalToDownload);
        QTimer::singleShot(0, this, &YoutubeDownloader::startNextDownload);
        return;
    }

    QStringList args;
    args << "-f" << "bestaudio/best"
         << "-x"
         << "--audio-format" << "mp3"
         << "--audio-quality" << "5"
         << "--no-playlist"
         << "--newline"
         << "-o" << filePath
         << task.videoUrl;

    qDebug() << "================================================";
    qDebug() << "🎯 INICIANDO DESCARGA";
    qDebug() << "   Video ID:" << task.videoId;
    qDebug() << "   Título:" << task.title;
    qDebug() << "   URL:" << task.videoUrl;
    qDebug() << "   Destino:" << filePath;
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

    m_currentDownloadProcess->start(m_ytdlpPath, args);
}

void YoutubeDownloader::onDownloadFinished(int exitCode,
                                           QProcess::ExitStatus status)
{
    QString filePath = ensureAudioCacheDir() + "/" + m_currentTask.videoId + ".mp3";

    qDebug() << "================================================";
    qDebug() << "📊 RESULTADO DE DESCARGA:";
    qDebug() << "   Video ID:" << m_currentTask.videoId;
    qDebug() << "   Título:" << m_currentTask.title;
    qDebug() << "   Exit Code:" << exitCode;
    qDebug() << "   Status:" << (status == QProcess::NormalExit ? "Normal" : "Crashed");
    qDebug() << "   Archivo existe:" << QFile::exists(filePath);

    if (QFile::exists(filePath)) {
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

    if (status == QProcess::NormalExit && exitCode == 0 && QFile::exists(filePath)) {
        QFileInfo fi(filePath);
        qint64 fileSize = fi.size();

        if (fileSize > m_maxFileSize) {
            QFile::remove(filePath);
            qDebug() << "❌ Muy grande, eliminado";
        } else if (fileSize < 100000) {
            QFile::remove(filePath);
            qDebug() << "❌ Descarga incompleta o corrupta (tamaño:" << fileSize << "bytes)";
        } else {
            m_currentCacheSize += fileSize;
            updateCacheEntry(m_currentTask.videoId, filePath, fileSize);

            qDebug() << "✅ Descarga completa:" << QString::number(fileSize / 1024.0 / 1024.0, 'f', 1) << "MB";

            m_downloadedCount++;
            emit downloadCountChanged(m_downloadedCount, m_totalToDownload);

            if (m_currentTask.emitWhenReady) {
                emit audioReady(filePath, m_currentTask.title,
                                m_currentTask.author.isEmpty() ? "Desconocido" : m_currentTask.author);
            }
        }
    } else {
        qWarning() << "⚠️ FALLÓ DESCARGA";
        qWarning() << "   Razón: Exit code" << exitCode << "| Status"
                   << (status == QProcess::NormalExit ? "Normal" : "Crashed");
        qWarning() << "   Archivo generado:" << QFile::exists(filePath);

        m_downloadedCount++;
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

            QString filePath = ensureAudioCacheDir() + "/" + videoId + ".mp3";

            DownloadTask t;
            t.videoId = videoId;
            t.title = title;
            t.author = author;
            t.videoUrl = "https://www.youtube.com/watch?v=" + videoId;
            t.emitWhenReady = true;

            m_downloadQueue.enqueue(t);

            if (m_cacheIndex.contains(videoId) && QFile::exists(filePath)) {
                QFileInfo fi(filePath);
                if (fi.size() > 100000) {
                    alreadyCached++;
                } else {
                    needsDownload++;
                }
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
    case QProcess::FailedToStart:
        errorStr = "yt-dlp no pudo iniciar. Descargando...";
        downloadYtDlp();
        break;
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

    QRegularExpression re("\\[download\\]\\s+(\\d+\\.?\\d*)%");
    auto match = re.match(output);

    if (match.hasMatch()) {
        QString percent = match.captured(1);
        emit progressUpdate(QStringLiteral("⬇️ %1/%2 - %3% - %4").arg(
            QString::number(m_downloadedCount + 1),
            QString::number(m_totalToDownload),
            percent,
            m_currentTask.title));
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
