import os
import numpy as np
import librosa
import glob


SAMPLE_RATE = 48000
DURATION = 4
IMG_H = 224
IMG_W = 287
TARGET_SIZE = IMG_H * IMG_W

DATA_DIR = "processed_data"
OUTPUT_FILE = "audio_10class_dataset.npy"


def process_single_audio(filepath):

    from scipy.io import wavfile
    sr, wav_data = wavfile.read(filepath)
    wav_data = wav_data.astype(np.float32)
    if len(wav_data.shape) > 1:
        wav_data = wav_data.mean(axis=1) 
    wav_data /= 32768.0  

    
    expected_len = SAMPLE_RATE * DURATION
    if len(wav_data) < expected_len:
        wav_data = np.pad(wav_data, (0, expected_len - len(wav_data)), mode='constant')
    else:
        wav_data = wav_data[:expected_len]

    if len(wav_data) > TARGET_SIZE:
        wav_data = wav_data[:TARGET_SIZE]
    elif len(wav_data) < TARGET_SIZE:
        wav_data = np.pad(wav_data, (0, TARGET_SIZE - len(wav_data)), mode='constant')
        
    matrix = wav_data.reshape(IMG_H, IMG_W)
    matrix = (matrix - np.min(matrix)) / (np.max(matrix) - np.min(matrix) + 1e-8)
    return matrix

def build_dataset():
    X = []
    Y = []

    # 自动遍历 0~9
    for digit in range(10):
        folder = os.path.join(DATA_DIR, str(digit))
        if not os.path.exists(folder):
            continue

        # 读取所有切片
        files = glob.glob(os.path.join(folder, "*.wav"))
        print(f"数字 {digit}：{len(files)} 个样本")

        for f in files:
            try:
                mat = process_single_audio(f)
                X.append(mat)
                Y.append(digit)
            except Exception as e:
                print(f"处理失败: {os.path.basename(f)} → {e}")
                continue

    X = np.array(X, dtype=np.float32)
    Y = np.array(Y, dtype=np.int64)

    # 保存
    np.save(OUTPUT_FILE, {"features": X, "labels": Y})
    print(f"\n数据集保存完成：{OUTPUT_FILE}")
    print(f"总样本：{len(X)}")
    print(f"特征形状：{X.shape}")
    print(f"标签形状：{Y.shape}")
    print(f"可直接用于 10 分类训练！")

if __name__ == "__main__":
    build_dataset()