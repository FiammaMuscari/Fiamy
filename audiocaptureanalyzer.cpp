#include "audiocaptureanalyzer.h"
#include <QtMath>
#include <QDebug>
#include <QMediaPlayer>
#include <QAudioBufferOutput>
#include <QAudioFormat>
#include <QDateTime>
#include <type_traits>

#ifdef Q_OS_WIN
#define MINIAUDIO_IMPLEMENTATION
#include "miniaudio.h"
#endif

AudioCaptureAnalyzer::AudioCaptureAnalyzer(QObject *parent)
    : QObject(parent)
#ifdef Q_OS_WIN
    , m_device(nullptr)
#endif
    , m_audioBufferOutput(nullptr)
    , m_isRunning(false)
    , m_lastEmitMs(0)
{
    resetSpectrum(0.0f);
}

AudioCaptureAnalyzer::~AudioCaptureAnalyzer()
{
    stop();
    detachPlayerTap();
}

QVariantList AudioCaptureAnalyzer::spectrum() const
{
    QMutexLocker locker(&m_mutex);
    return m_spectrum;
}

bool AudioCaptureAnalyzer::isRunning() const
{
    return m_isRunning;
}

void AudioCaptureAnalyzer::start()
{
#ifdef Q_OS_WIN
    if (m_device) {
        qDebug() << "AudioCaptureAnalyzer: Ya está ejecutándose";
        return;
    }

    m_device = new ma_device;

    ma_device_config config = ma_device_config_init(ma_device_type_loopback);
    config.capture.format   = ma_format_f32;
    config.capture.channels = 2;
    config.sampleRate       = 44100;
    config.dataCallback     = dataCallback;
    config.pUserData        = this;

    if (ma_device_init(nullptr, &config, m_device) != MA_SUCCESS) {
        qWarning() << "AudioCaptureAnalyzer: Error al inicializar dispositivo de audio";
        delete m_device;
        m_device = nullptr;
        return;
    }

    if (ma_device_start(m_device) != MA_SUCCESS) {
        qWarning() << "AudioCaptureAnalyzer: Error al iniciar dispositivo de audio";
        ma_device_uninit(m_device);
        delete m_device;
        m_device = nullptr;
        return;
    }

    m_isRunning = true;
    qDebug() << "AudioCaptureAnalyzer: Captura de audio iniciada (loopback)";
#else
    if (m_isRunning) {
        qDebug() << "AudioCaptureAnalyzer: ya está ejecutándose";
        return;
    }

    m_isRunning = true;
    setupPlayerTap();
    qDebug() << "AudioCaptureAnalyzer: analizador iniciado con audio real del reproductor";
#endif
}

void AudioCaptureAnalyzer::stop()
{
#ifdef Q_OS_WIN
    if (m_device) {
        ma_device_uninit(m_device);
        delete m_device;
        m_device = nullptr;
        m_isRunning = false;
        qDebug() << "AudioCaptureAnalyzer: Captura de audio detenida";
    }
#else
    m_isRunning = false;
    resetSpectrum(0.0f);
    qDebug() << "AudioCaptureAnalyzer: analizador detenido";
#endif
}

void AudioCaptureAnalyzer::attachToPlayer(QObject *playerObject)
{
    QMediaPlayer *player = qobject_cast<QMediaPlayer*>(playerObject);
    if (m_player == player) {
        return;
    }

    detachPlayerTap();
    m_player = player;
    setupPlayerTap();
}

void AudioCaptureAnalyzer::resetSpectrum(float value)
{
    QVariantList newSpectrum;
    newSpectrum.reserve(SPECTRUM_SIZE);

    for (int i = 0; i < SPECTRUM_SIZE; ++i) {
        newSpectrum.append(qBound(0.0f, value, 1.0f));
    }

    QMutexLocker locker(&m_mutex);
    m_spectrum = newSpectrum;
}

void AudioCaptureAnalyzer::setupPlayerTap()
{
#if !defined(Q_OS_WIN)
    if (!m_player) {
        qDebug() << "AudioCaptureAnalyzer: sin MediaPlayer adjunto, esperando conexión";
        return;
    }

    if (!m_audioBufferOutput) {
        m_audioBufferOutput = new QAudioBufferOutput(this);
        connect(m_audioBufferOutput, &QAudioBufferOutput::audioBufferReceived,
                this, &AudioCaptureAnalyzer::handleAudioBuffer);
    }

    m_player->setAudioBufferOutput(m_audioBufferOutput);
    disconnect(m_player, nullptr, this, nullptr);
    connect(m_player, &QObject::destroyed, this, [this]() {
        m_player = nullptr;
        resetSpectrum(0.0f);
        emit spectrumChanged();
    });
#endif
}

void AudioCaptureAnalyzer::detachPlayerTap()
{
#if !defined(Q_OS_WIN)
    if (m_player && m_audioBufferOutput && m_player->audioBufferOutput() == m_audioBufferOutput) {
        m_player->setAudioBufferOutput(nullptr);
    }
#endif
}

#ifdef Q_OS_WIN
void AudioCaptureAnalyzer::dataCallback(ma_device* pDevice, void* pOutput,
                                        const void* pInput, unsigned int frameCount)
{
    Q_UNUSED(pOutput);

    auto* analyzer = static_cast<AudioCaptureAnalyzer*>(pDevice->pUserData);
    if (!analyzer || !pInput || frameCount == 0) return;

    const float* samples = static_cast<const float*>(pInput);
    float monoSamples[FFT_SIZE];
    int monoCount = 0;

    for (unsigned int i = 0; i < frameCount && monoCount < FFT_SIZE; ++i) {
        monoSamples[monoCount++] = (samples[i * 2] + samples[i * 2 + 1]) * 0.5f;
    }

    analyzer->calculateFFT(monoSamples, monoCount);
}
#endif

void AudioCaptureAnalyzer::calculateFFT(const float* samples, int count)
{
    if (!samples || count < 64) {
        return;
    }

    const qint64 nowMs = QDateTime::currentMSecsSinceEpoch();
    const qint64 lastEmit = m_lastEmitMs.load(std::memory_order_relaxed);
    if ((nowMs - lastEmit) < 33) {
        return;
    }

    const int sampleCount = qMin(count, FFT_SIZE);
    QVariantList newSpectrum;
    newSpectrum.reserve(SPECTRUM_SIZE);

    for (int i = 0; i < SPECTRUM_SIZE; ++i) {
        const float startRatio = qPow(float(i) / SPECTRUM_SIZE, 1.8f);
        const float endRatio = qPow(float(i + 1) / SPECTRUM_SIZE, 1.8f);

        int startIdx = qBound(0, int(startRatio * sampleCount), sampleCount - 1);
        int endIdx = qBound(startIdx + 1, int(endRatio * sampleCount), sampleCount);

        float sum = 0.0f;
        int sampleCounter = 0;

        for (int j = startIdx; j < endIdx; ++j) {
            float weighted = qAbs(samples[j]) * hammingWindow(j - startIdx, endIdx - startIdx);
            sum += weighted;
            sampleCounter++;
        }

        float avg = sampleCounter > 0 ? sum / sampleCounter : 0.0f;
        avg *= (1.0f + (float(i) / SPECTRUM_SIZE) * 0.35f);
        avg = qBound(0.0f, avg * 8.0f, 1.0f);
        avg = qPow(avg, 0.7f);

        if (avg < 0.035f) {
            avg = 0.0f;
        }

        newSpectrum.append(avg);
    }

    {
        QMutexLocker locker(&m_mutex);
        m_spectrum = newSpectrum;
    }

    m_lastEmitMs.store(nowMs, std::memory_order_relaxed);
    emit spectrumChanged();
}

#ifndef Q_OS_WIN
void AudioCaptureAnalyzer::handleAudioBuffer(const QAudioBuffer &buffer)
{
    if (!m_isRunning) {
        return;
    }

    if (!buffer.isValid() || buffer.frameCount() <= 0) {
        resetSpectrum(0.0f);
        emit spectrumChanged();
        return;
    }

    const QAudioFormat format = buffer.format();
    const int channels = qMax(1, format.channelCount());
    QList<float> monoSamples;
    monoSamples.reserve(qMin<int>(FFT_SIZE, buffer.frameCount()));

    auto appendMonoSamples = [&](const auto *data) {
        const int frameCount = buffer.frameCount();
        for (int frame = 0; frame < frameCount && monoSamples.size() < FFT_SIZE; ++frame) {
            float sum = 0.0f;
            const int base = frame * channels;
            for (int ch = 0; ch < channels; ++ch) {
                using SampleType = std::decay_t<decltype(data[0])>;
                if constexpr (std::is_same_v<SampleType, float>) {
                    sum += data[base + ch];
                } else if constexpr (std::is_same_v<SampleType, unsigned char>) {
                    sum += (float(data[base + ch]) - 128.0f) / 128.0f;
                } else if constexpr (std::is_same_v<SampleType, short>) {
                    sum += float(data[base + ch]) / 32768.0f;
                } else {
                    sum += float(data[base + ch]) / 2147483648.0f;
                }
            }
            monoSamples.append(sum / channels);
        }
    };

    switch (format.sampleFormat()) {
    case QAudioFormat::Float:
        appendMonoSamples(buffer.constData<float>());
        break;
    case QAudioFormat::UInt8:
        appendMonoSamples(buffer.constData<unsigned char>());
        break;
    case QAudioFormat::Int16:
        appendMonoSamples(buffer.constData<short>());
        break;
    case QAudioFormat::Int32:
        appendMonoSamples(buffer.constData<int>());
        break;
    default:
        resetSpectrum(0.0f);
        emit spectrumChanged();
        return;
    }

    if (monoSamples.isEmpty()) {
        resetSpectrum(0.0f);
        emit spectrumChanged();
        return;
    }

    calculateFFT(monoSamples.constData(), monoSamples.size());
}
#endif

float AudioCaptureAnalyzer::hammingWindow(int n, int N)
{
    if (N <= 1) {
        return 1.0f;
    }
    return 0.54f - 0.46f * qCos(2.0f * M_PI * n / (N - 1));
}
