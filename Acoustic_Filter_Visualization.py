import os
import numpy as np
import scipy.io.wavfile as wav
from scipy.signal import butter, filtfilt, find_peaks, hilbert
import matplotlib.pyplot as plt
import glob


TARGET_SR = 48000
CYCLE_DURATION_SECONDS = 4.0
BEEP_FREQ = 4500
LOW_CUT = 1000
HIGH_CUT = 5000
TARGET_LENGTH = 4 * TARGET_SR

INPUT_DIR = "recordings"
OUTPUT_DIR = "processed_data"

def bandpass_filter(audio, sr, low=1000, high=5000, order=4):
    nyq = 0.5 * sr
    low = low / nyq
    high = high / nyq
    b, a = butter(order, [low, high], btype="band")
    return filtfilt(b, a, audio)

def detect_beep_peaks(audio, sr):
    nyq = 0.5 * sr
    b, a = butter(4, BEEP_FREQ / nyq, btype="high")
    filtered = filtfilt(b, a, audio)

    analytic = hilbert(filtered)
    envelope = np.abs(analytic)

    b2, a2 = butter(2, 50 / nyq, btype="low")
    env_smooth = filtfilt(b2, a2, envelope)

    threshold = 0.3 * np.max(env_smooth)
    min_dist = int(3.5 * sr)
    peaks, _ = find_peaks(
        env_smooth,
        height=threshold * 0.4,
        distance=min_dist,
        prominence=threshold * 0.3
    )
    return peaks, env_smooth


def plot_all_visuals(audio, sr, peaks, envelope, filtered_seg, digit):
    time_axis = np.arange(len(audio)) / sr
    plt.figure(figsize=(16, 5))
    plt.plot(time_axis, audio, color='#1f77b4', alpha=0.7, label='Original Waveform')
    plt.scatter(np.array(peaks) / sr, audio[peaks], color='red', s=70, zorder=5, label='Detected Beep')

    for i in range(len(peaks) - 1):
        st = peaks[i]
        ed = st + TARGET_LENGTH
        if ed >= len(audio): break
        plt.axvspan(st / sr, ed / sr, color='green', alpha=0.2, label='4s Slice' if i == 0 else "")

    plt.title(f"Audio Waveform & Beep Detection (Digit {digit})")
    plt.xlabel("Time (s)")
    plt.ylabel("Amplitude")
    plt.legend()
    plt.grid(alpha=0.3)
    plt.tight_layout()
    plt.savefig(f"waveform_beep_slice.png", dpi=300)
    plt.show()

    plt.figure(figsize=(16, 4))
    plt.plot(time_axis, envelope, color='#ff7f0e', label='Smoothed Envelope')
    plt.scatter(np.array(peaks) / sr, envelope[peaks], color='red', s=70, zorder=5)
    threshold = 0.3 * np.max(envelope)
    plt.axhline(threshold, color='gray', linestyle='--', label='Threshold')
    plt.title(f"Beep Envelope Detection (Digit {digit})")
    plt.xlabel("Time (s)")
    plt.ylabel("Envelope Amplitude")
    plt.legend()
    plt.grid(alpha=0.3)
    plt.tight_layout()
    plt.savefig(f"beep_envelope.png", dpi=300)
    plt.show()

    slice_example = audio[peaks[0]: peaks[0] + TARGET_LENGTH]
    filtered_example = bandpass_filter(slice_example, sr, LOW_CUT, HIGH_CUT)
    t_slice = np.arange(len(slice_example)) / sr

    plt.figure(figsize=(14, 6))
    plt.subplot(2, 1, 1)
    plt.plot(t_slice, slice_example, color='blue')
    plt.title(f"Original Slice (Before Filter)")
    plt.ylabel("Amplitude")
    plt.grid(alpha=0.3)

    plt.subplot(2, 1, 2)
    plt.plot(t_slice, filtered_example, color='red')
    plt.title(f"Filtered Slice (After 1000-5000Hz Bandpass)")
    plt.xlabel("Time (s)")
    plt.ylabel("Amplitude")
    plt.grid(alpha=0.3)

    plt.tight_layout()
    plt.savefig(f"before_after_filter.png", dpi=300)
    plt.show()


def process_file(file_path, digit, out_dir):
    sr, audio = wav.read(file_path)
    audio = audio.astype(np.float32)
    if len(audio.shape) > 1:
        audio = audio.mean(axis=1)
    audio /= np.max(np.abs(audio))

    peaks, envelope = detect_beep_peaks(audio, sr)
    base = os.path.splitext(os.path.basename(file_path))[0]
    count = 0

    # 正常切片保存
    for i in range(len(peaks) - 1):
        start = peaks[i]
        end = start + TARGET_LENGTH
        if end > len(audio):
            continue

        seg = audio[start:end]
        seg = bandpass_filter(seg, sr, LOW_CUT, HIGH_CUT)

        out_path = os.path.join(out_dir, f"digit{digit}_{base}_slice_{count}.wav")
        wav.write(out_path, sr, seg.astype(np.float32))
        count += 1

    return count, audio, sr, peaks, envelope


def main():
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    total = 0
    vis_done = False

    for digit in range(10):
        in_dir = os.path.join(INPUT_DIR, str(digit))
        out_dir = os.path.join(OUTPUT_DIR, str(digit))
        if not os.path.exists(in_dir):
            continue
        os.makedirs(out_dir, exist_ok=True)

        print(f"处理数字 {digit}")
        files = glob.glob(os.path.join(in_dir, "*.wav"))
        for f in files:
            cnt, audio, sr, peaks, envelope = process_file(f, digit, out_dir)
            total += cnt

            if not vis_done and len(peaks) > 0:
                slice_example = audio[peaks[0]: peaks[0] + TARGET_LENGTH]
                filtered_example = bandpass_filter(slice_example, sr, LOW_CUT, HIGH_CUT)
                plot_all_visuals(audio, sr, peaks, envelope, filtered_example, 0)
                vis_done = True

    print(f"\n 全部完成！总切片数：{total}")
    print(f"原始路径：{INPUT_DIR}")
    print(f"输出路径：{OUTPUT_DIR}")


if __name__ == "__main__":
    main()