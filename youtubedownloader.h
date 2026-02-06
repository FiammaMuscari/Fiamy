#ifndef YOUTUBEDOWNLOADER_H
#define YOUTUBEDOWNLOADER_H

#include <QObject>
#include <QProcess>
#include <QString>
#include <QQueue>
#include <QMap>
#include <QDateTime>

struct CacheEntry
{
    QString videoId;
    QString filePath;
    qint64 fileSize;
    QDateTime lastAccessed;
};

QDataStream &operator<<(QDataStream &out, const CacheEntry &entry);
QDataStream &operator>>(QDataStream &in, CacheEntry &entry);

struct DownloadTask
{
    QString videoId;
    QString title;
    QString author;
    QString videoUrl;
    bool emitWhenReady;
};

class YoutubeDownloader : public QObject
{
    Q_OBJECT
public:
    explicit YoutubeDownloader(QObject *parent = nullptr);
    ~YoutubeDownloader();

    Q_INVOKABLE void getAudioUrl(const QString &youtubeUrl);
    Q_INVOKABLE void cancelDownload();
    Q_INVOKABLE void clearCache();
    Q_INVOKABLE void removeFromCache(const QString &videoId);

signals:
    void audioReady(const QString &filePath, const QString &title, const QString &author);
    void errorOccurred(const QString &error);
    void progressUpdate(const QString &message);
    void downloadCountChanged(int current, int total);
    void ytdlpDownloading(const QString &message);

private slots:
    void onProcessFinished(int exitCode, QProcess::ExitStatus status);
    void onProcessError(QProcess::ProcessError error);
    void onReadyReadStandardError();
    void onDownloadFinished(int exitCode, QProcess::ExitStatus status);
    void onDownloadProgress();
    void onDownloadStderr();

private:
    void loadCacheIndex();
    void saveCacheIndex();
    void updateCacheEntry(const QString &videoId, const QString &filePath, qint64 size);
    void calculateCurrentCacheSize();
    void cleanOldestEntries(qint64 bytesNeeded);
    void downloadYtDlp();
    void checkYtDlpVersion();
    bool makeSpaceForFile(qint64 estimatedSize);
    QString extractVideoId(const QString &url);
    QString extractPlaylistId(const QString &url);
    QString cleanUrlForPlaylist(const QString &url);
    QString ensureAudioCacheDir();
    bool isPlaylistUrl(const QString &url);
    void startNextDownload();

    QString m_ytdlpPath;
    QProcess *m_process;
    QProcess *m_currentDownloadProcess;
    QQueue<DownloadTask> m_downloadQueue;
    DownloadTask m_currentTask;
    QMap<QString, CacheEntry> m_cacheIndex;
    qint64 m_maxCacheSize;
    qint64 m_currentCacheSize;
    qint64 m_maxFileSize;
    int m_maxSongsPerPlaylist;
    QString m_currentUrl;
    bool m_isPlaylist;
    int m_downloadedCount;
    int m_totalToDownload;
};

#endif
