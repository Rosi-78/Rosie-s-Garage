import numpy as np
import matplotlib.pyplot as plt


data = np.load("audio_10class_dataset.npy", allow_pickle=True).item()
X = data["features"]
Y = data["labels"]
print("你的真实特征形状 =", X.shape)
print("总样本数：", len(X))
print("每个样本形状：", X[0].shape)
print("标签 0~9 分布：", np.bincount(Y))

plt.figure(figsize=(15, 5))
for i in range(9):
    idx = [36,120,200,260,360,450,520,600,680,712]
    plt.subplot(3, 3, i+1)
    plt.imshow(X[idx[i]], cmap="jet")
    plt.title(f"Label: {Y[idx[i]]}")
    plt.axis("off")

plt.suptitle("Processed Audio  Images (After Preprocessing)")
plt.tight_layout()
plt.show()