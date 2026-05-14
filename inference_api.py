import os
import numpy as np
import torch
import torch.nn as nn
import scipy.io.wavfile as wav
from scipy.signal import butter, filtfilt, find_peaks, hilbert
from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pathlib import Path
from typing import Dict, Any

# -------------------------- 全局配置 --------------------------
class Config:
    TARGET_SR = 48000
    CYCLE_DURATION_SECONDS = 4.0
    BEEP_FREQ = 4500
    LOW_CUT = 1000
    HIGH_CUT = 5000
    TARGET_LENGTH = 4 * TARGET_SR
    IMG_H = 224
    IMG_W = 287
    TARGET_SIZE = IMG_H * IMG_W
    BEST_MODEL_PATH = "best_simple_cnn_10class.pth"
    DEVICE = "cuda" if torch.cuda.is_available() else "cpu"

cfg = Config()

# -------------------------- FastAPI --------------------------
app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# -------------------------- 音频预处理 --------------------------
def bandpass_filter(audio: np.ndarray, sr: int, low: int = cfg.LOW_CUT, high: int = cfg.HIGH_CUT, order: int = 4) -> np.ndarray:
    nyq = 0.5 * sr
    low_norm = low / nyq
    high_norm = high / nyq
    b, a = butter(order, [low_norm, high_norm], btype="band")
    return filtfilt(b, a, audio)

def detect_beep_peaks(audio: np.ndarray, sr: int):
    nyq = 0.5 * sr
    b, a = butter(4, cfg.BEEP_FREQ / nyq, btype="high")
    filtered = filtfilt(b, a, audio)
    analytic = hilbert(filtered)
    envelope = np.abs(analytic)
    b2, a2 = butter(2, 50 / nyq, btype="low")
    env_smooth = filtfilt(b2, a2, envelope)
    threshold = 0.3 * np.max(env_smooth)
    min_dist = int(3.5 * sr)
    peaks, _ = find_peaks(env_smooth, height=threshold*0.4, distance=min_dist, prominence=threshold*0.3)
    return peaks, env_smooth

def process_single_audio(audio_data: np.ndarray, sr: int) -> np.ndarray:
    audio_data = audio_data.astype(np.float32)
    if len(audio_data.shape) > 1:
        audio_data = audio_data.mean(axis=1)
    audio_data /= np.max(np.abs(audio_data)) + 1e-8
    peaks, _ = detect_beep_peaks(audio_data, sr)
    if len(peaks) == 0:
        raise ValueError("未检测到蜂鸣信号")
    start = peaks[0]
    end = start + cfg.TARGET_LENGTH
    if end > len(audio_data):
        audio_slice = audio_data[start:]
        audio_slice = np.pad(audio_slice, (0, cfg.TARGET_LENGTH - len(audio_slice)), mode='constant')
    else:
        audio_slice = audio_data[start:end]
    audio_slice = bandpass_filter(audio_slice, sr)
    if len(audio_slice) > cfg.TARGET_SIZE:
        audio_slice = audio_slice[:cfg.TARGET_SIZE]
    elif len(audio_slice) < cfg.TARGET_SIZE:
        audio_slice = np.pad(audio_slice, (0, cfg.TARGET_SIZE - len(audio_slice)), mode='constant')
    matrix = audio_slice.reshape(cfg.IMG_H, cfg.IMG_W)
    matrix = (matrix - np.min(matrix)) / (np.max(matrix) - np.min(matrix) + 1e-8)
    return matrix

# -------------------------- 模型 --------------------------
class SimpleCNN(nn.Module):
    def __init__(self, input_shape: tuple):
        super().__init__()
        self.conv1 = nn.Conv2d(1, 16, 3, padding=1)
        self.pool = nn.MaxPool2d(2)
        self.conv2 = nn.Conv2d(16, 32, 3, padding=1)
        with torch.no_grad():
            dummy = torch.randn(1, *input_shape)
            dummy = self.pool(torch.relu(self.conv1(dummy)))
            dummy = self.pool(torch.relu(self.conv2(dummy)))
            self.flatten_dim = dummy.numel()
        self.fc1 = nn.Linear(self.flatten_dim, 256)
        self.fc2 = nn.Linear(256, 10)

    def forward(self, x):
        x = self.pool(torch.relu(self.conv1(x)))
        x = self.pool(torch.relu(self.conv2(x)))
        x = x.view(-1, self.flatten_dim)
        x = torch.relu(self.fc1(x))
        x = self.fc2(x)
        return x

def load_model():
    input_shape = (1, cfg.IMG_H, cfg.IMG_W)
    model = SimpleCNN(input_shape).to(cfg.DEVICE)
    checkpoint = torch.load(cfg.BEST_MODEL_PATH, map_location=cfg.DEVICE)
    model.load_state_dict(checkpoint['model_state_dict'])
    model.eval()
    return model

model = load_model()

# -------------------------- 预测接口 --------------------------
@app.post("/predict", response_model=Dict[str, Any])
async def predict_audio(file: UploadFile = File(...)) -> Dict[str, Any]:
    try:
        if not file.filename or not file.filename.endswith(".wav"):
            raise HTTPException(status_code=400, detail="仅支持WAV格式")

        temp_wav = Path("temp.wav")
        try:
            with open(temp_wav, "wb") as f:
                f.write(await file.read())
            sr, audio_data = wav.read(temp_wav)
        finally:
            if temp_wav.exists():
                os.remove(temp_wav)

        matrix = process_single_audio(audio_data, sr)

        with torch.no_grad():
            input_tensor = torch.FloatTensor(matrix).unsqueeze(0).unsqueeze(0).to(cfg.DEVICE)
            output = model(input_tensor)
            pred_prob = torch.softmax(output, dim=1)
            pred_label = torch.argmax(pred_prob, dim=1).item()
            conf = pred_prob[0][pred_label].item()

        # ✅ 正确返回，无未定义变量，和前端完全对齐
        return {
            "code": 200,
            "message": "预测成功",
            "result": {
                "predicted_digit": int(pred_label),
                "confidence": round(conf * 100, 2),
                "probabilities": [round(float(p) * 100, 2) for p in pred_prob[0]],
                "file_name": file.filename
            }
        }

    except HTTPException as e:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# -------------------------- 启动 --------------------------
if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app="inference_api:app", host="0.0.0.0", port=8000, reload=True)