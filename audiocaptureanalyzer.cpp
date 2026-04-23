#include "audiocaptureanalyzer.h"
#include <QtMath>
#include <QDebug>
#include <QMediaPlayer>
#include <QAudioBufferOutput>
#include <QAudioFormat>
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
    QList<float> monoSamples;
    monoSamples.reserve(FFT_SIZE);

    for (unsigned int i = 0; i < frameCount && monoSamples.size() < FFT_SIZE; ++i) {
        monoSamples.append((samples[i * 2] + samples[i * 2 + 1]) * 0.5f);
    }

    analyzer->calculateFFT(monoSamples.constData(), monoSamples.size());
}
#endif

void AudioCaptureAnalyzer::calculateFFT(const float* samples, int count)
{
    if (!samples || count < 64) return; // Muy pocas muestras

    const int N = qMin(count, FFT_SIZE);
    QList<float> magnitudes;
    magnitudes.reserve(N / 2);

    // DFT simple (solo calculamos la mitad - frecuencias positivas)
    for (int k = 0; k < N / 2; ++k) {
        float real = 0.0f;
        float imag = 0.0f;

        for (int n = 0; n < N; ++n) {
            float window = hammingWindow(n, N);
            float angle = -2.0f * M_PI * k * n / N;
            real += samples[n] * window * qCos(angle);
            imag += samples[n] * window * qSin(angle);
        }

        float magnitude = qSqrt(real * real + imag * imag) / N;
        magnitudes.append(magnitude);
    }

    if (magnitudes.isEmpty()) return;

    // Agrupar frecuencias en SPECTRUM_SIZE bandas
    QVariantList newSpectrum;
    const int bandsPerBar = qMax(1, magnitudes.size() / SPECTRUM_SIZE);

    for (int i = 0; i < SPECTRUM_SIZE; ++i) {
        float sum = 0.0f;
        int bandCount = 0;

        for (int j = 0; j < bandsPerBar; ++j) {
            int idx = i * bandsPerBar + j;
            if (idx < magnitudes.size()) {
                sum += magnitudes[idx];
                bandCount++;
            }
        }

        float avg = bandCount > 0 ? sum / bandCount : 0.0f;

        // Normalizar y escalar para visualización
        avg = qBound(0.0f, avg * 50.0f, 1.0f);

        // Aplicar escala logarítmica para mejor visualización
        avg = qPow(avg, 0.6f);

        // Noise gate para que en silencio quede quieto
        if (avg < 0.035f) {
            avg = 0.0f;
        }

        newSpectrum.append(avg);
    }

    // Actualizar spectrum de forma thread-safe
    QMutexLocker locker(&m_mutex);
    m_spectrum = newSpectrum;
    locker.unlock();

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
    return 0.54f - 0.46f * qCos(2.0f * M_PI * n / (N - 1));
}
