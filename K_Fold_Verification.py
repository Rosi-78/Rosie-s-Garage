import numpy as np
import torch
import torch.nn as nn
import torch.optim as optim
from torch.utils.data import DataLoader, TensorDataset
from sklearn.model_selection import train_test_split, KFold  # 新增KFold
from sklearn.metrics import (
    classification_report, confusion_matrix, accuracy_score,
    precision_recall_fscore_support
)
import matplotlib.pyplot as plt
import seaborn as sns

plt.rcParams['font.family'] = 'Arial'
plt.rcParams['axes.unicode_minus'] = False  # 解决负号显示问题

DATA_PATH = "audio_10class_dataset.npy"
BATCH_SIZE = 16
EPOCHS = 50
LR = 0.001
NUM_CLASSES = 10
CLASS_NAMES = [f"Class {i}" for i in range(NUM_CLASSES)]
BEST_MODEL_PATH = "best_simple_cnn_10class.pth"
K_FOLDS = 5
DEVICE = "cuda" if torch.cuda.is_available() else "cpu"


class SimpleCNN(nn.Module):
    def __init__(self, input_shape):
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
        self.fc2 = nn.Linear(256, NUM_CLASSES)

    def forward(self, x):
        x = self.pool(torch.relu(self.conv1(x)))
        x = self.pool(torch.relu(self.conv2(x)))
        x = x.view(-1, self.flatten_dim)
        x = torch.relu(self.fc1(x))
        x = self.fc2(x)
        return x


def plot_train_history(train_losses, train_accs, val_losses, val_accs, fold_idx):
    """Plot training/validation loss and accuracy curves (带折数标识)"""
    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(15, 5))

    # Loss curve
    ax1.plot(range(1, EPOCHS + 1), train_losses, label='Training Loss', color='blue', linewidth=2)
    ax1.plot(range(1, EPOCHS + 1), val_losses, label='Validation Loss', color='red', linewidth=2)
    ax1.set_xlabel('Epoch')
    ax1.set_ylabel('Loss')
    ax1.set_title(f'Fold {fold_idx+1} - Training/Validation Loss Curve')
    ax1.legend()
    ax1.grid(alpha=0.3)

    # Accuracy curve
    ax2.plot(range(1, EPOCHS + 1), train_accs, label='Training Accuracy', color='blue', linewidth=2)
    ax2.plot(range(1, EPOCHS + 1), val_accs, label='Validation Accuracy', color='red', linewidth=2)
    ax2.set_xlabel('Epoch')
    ax2.set_ylabel('Accuracy')
    ax2.set_title(f'Fold {fold_idx+1} - Training/Validation Accuracy Curve')
    ax2.legend()
    ax2.grid(alpha=0.3)

    plt.tight_layout()
    plt.savefig(f'train_history_fold_{fold_idx+1}.png', dpi=300, bbox_inches='tight')
    plt.show()


def plot_confusion_matrix(y_true, y_pred, class_names, fold_idx):
    """Plot confusion matrix (带折数标识)"""
    cm = confusion_matrix(y_true, y_pred)
    fig, ax = plt.subplots(figsize=(12, 10))

    sns.heatmap(cm, annot=True, fmt='d', cmap='Blues', ax=ax,
                xticklabels=class_names, yticklabels=class_names,
                cbar_kws={'label': 'Count'})

    ax.set_xlabel('Predicted Label')
    ax.set_ylabel('True Label')
    ax.set_title(f'Fold {fold_idx+1} - Confusion Matrix')

    plt.xticks(rotation=45)
    plt.yticks(rotation=0)
    plt.tight_layout()
    plt.savefig(f'confusion_matrix_fold_{fold_idx+1}.png', dpi=300, bbox_inches='tight')
    plt.show()


def plot_class_metrics(y_true, y_pred, class_names, fold_idx):
    """Plot per-class metrics (带折数标识)"""
    # Calculate metrics
    precision, recall, f1, _ = precision_recall_fscore_support(
        y_true, y_pred, average=None, labels=range(len(class_names))
    )
    accuracy_per_class = []
    for i in range(len(class_names)):
        mask = y_true == i
        if np.sum(mask) > 0:
            accuracy_per_class.append(accuracy_score(y_true[mask], y_pred[mask]))
        else:
            accuracy_per_class.append(0.0)

    # Plot subplots
    fig, ((ax1, ax2), (ax3, ax4)) = plt.subplots(2, 2, figsize=(16, 12))
    x = np.arange(len(class_names))
    width = 0.6

    # Accuracy per class
    ax1.bar(x, accuracy_per_class, width, color='#1f77b4', alpha=0.8)
    ax1.set_xlabel('Class')
    ax1.set_ylabel('Accuracy')
    ax1.set_title(f'Fold {fold_idx+1} - Per-Class Accuracy')
    ax1.set_xticks(x)
    ax1.set_xticklabels(class_names, rotation=45)
    ax1.grid(alpha=0.3, axis='y')
    ax1.set_ylim(0, 1.05)

    # Precision per class
    ax2.bar(x, precision, width, color='#ff7f0e', alpha=0.8)
    ax2.set_xlabel('Class')
    ax2.set_ylabel('Precision')
    ax2.set_title(f'Fold {fold_idx+1} - Per-Class Precision')
    ax2.set_xticks(x)
    ax2.set_xticklabels(class_names, rotation=45)
    ax2.grid(alpha=0.3, axis='y')
    ax2.set_ylim(0, 1.05)

    # Recall per class
    ax3.bar(x, recall, width, color='#2ca02c', alpha=0.8)
    ax3.set_xlabel('Class')
    ax3.set_ylabel('Recall')
    ax3.set_title(f'Fold {fold_idx+1} - Per-Class Recall')
    ax3.set_xticks(x)
    ax3.set_xticklabels(class_names, rotation=45)
    ax3.grid(alpha=0.3, axis='y')
    ax3.set_ylim(0, 1.05)

    # F1 Score per class
    ax4.bar(x, f1, width, color='#d62728', alpha=0.8)
    ax4.set_xlabel('Class')
    ax4.set_ylabel('F1 Score')
    ax4.set_title(f'Fold {fold_idx+1} - Per-Class F1 Score')
    ax4.set_xticks(x)
    ax4.set_xticklabels(class_names, rotation=45)
    ax4.grid(alpha=0.3, axis='y')
    ax4.set_ylim(0, 1.05)

    plt.tight_layout()
    plt.savefig(f'class_metrics_fold_{fold_idx+1}.png', dpi=300, bbox_inches='tight')
    plt.show()


def train_single_fold(X, y, train_idx, val_idx, fold_idx):
    """训练单折模型"""
    # 划分当前折的训练/验证集
    X_train, X_val = X[train_idx], X[val_idx]
    y_train, y_val = y[train_idx], y[val_idx]

    # 构建DataLoader
    train_dataset = TensorDataset(torch.FloatTensor(X_train), torch.LongTensor(y_train))
    val_dataset = TensorDataset(torch.FloatTensor(X_val), torch.LongTensor(y_val))
    train_loader = DataLoader(train_dataset, batch_size=BATCH_SIZE, shuffle=True)
    val_loader = DataLoader(val_dataset, batch_size=BATCH_SIZE, shuffle=False)

    # 初始化模型
    input_shape = X_train[0].shape
    model = SimpleCNN(input_shape).to(DEVICE)
    criterion = nn.CrossEntropyLoss()
    optimizer = optim.Adam(model.parameters(), lr=LR)

    # 训练记录
    train_losses = []
    train_accs = []
    val_losses = []
    val_accs = []
    best_val_acc = 0.0
    best_epoch = 0

    print(f"\n===== Training Fold {fold_idx+1}/{K_FOLDS} =====")
    for epoch in range(EPOCHS):
        # 训练阶段
        model.train()
        train_loss = 0
        train_correct = 0
        train_total = 0

        for data, label in train_loader:
            data, label = data.to(DEVICE), label.to(DEVICE)
            optimizer.zero_grad()

            output = model(data)
            loss = criterion(output, label)
            loss.backward()
            optimizer.step()

            train_loss += loss.item()
            pred = output.argmax(dim=1)
            train_correct += (pred == label).sum().item()
            train_total += label.size(0)

        train_epoch_loss = train_loss / len(train_loader)
        train_epoch_acc = train_correct / train_total
        train_losses.append(train_epoch_loss)
        train_accs.append(train_epoch_acc)

        # 验证阶段
        model.eval()
        val_loss = 0
        val_correct = 0
        val_total = 0
        all_preds = []
        all_labels = []

        with torch.no_grad():
            for data, label in val_loader:
                data, label = data.to(DEVICE), label.to(DEVICE)
                output = model(data)
                loss = criterion(output, label)
                val_loss += loss.item()

                pred = output.argmax(dim=1)
                val_correct += (pred == label).sum().item()
                val_total += label.size(0)

                all_preds.extend(pred.cpu().numpy())
                all_labels.extend(label.cpu().numpy())

        val_epoch_loss = val_loss / len(val_loader)
        val_epoch_acc = val_correct / val_total
        val_losses.append(val_epoch_loss)
        val_accs.append(val_epoch_acc)

        # 保存当前折最优模型
        if val_epoch_acc > best_val_acc:
            best_val_acc = val_epoch_acc
            best_epoch = epoch + 1
            torch.save({
                'fold': fold_idx+1,
                'epoch': epoch + 1,
                'model_state_dict': model.state_dict(),
                'optimizer_state_dict': optimizer.state_dict(),
                'val_accuracy': val_epoch_acc,
            }, f"best_model_fold_{fold_idx+1}.pth")

        # 打印epoch信息
        if (epoch + 1) % 5 == 0:  # 每5个epoch打印一次，减少输出
            print(f"Epoch {epoch + 1:2d}/{EPOCHS} | "
                  f"Train Loss: {train_epoch_loss:.4f} | Train Acc: {train_epoch_acc:.2%} | "
                  f"Val Loss: {val_epoch_loss:.4f} | Val Acc: {val_epoch_acc:.2%} | "
                  f"Best Val Acc: {best_val_acc:.2%} (Epoch {best_epoch})")

    # 当前折可视化
    plot_train_history(train_losses, train_accs, val_losses, val_accs, fold_idx)
    plot_confusion_matrix(all_labels, all_preds, CLASS_NAMES, fold_idx)
    plot_class_metrics(all_labels, all_preds, CLASS_NAMES, fold_idx)

    # 计算当前折的综合指标
    overall_acc = accuracy_score(all_labels, all_preds)
    avg_precision, avg_recall, avg_f1, _ = precision_recall_fscore_support(
        all_labels, all_preds, average='weighted'
    )

    # 保存当前折分类报告
    report = classification_report(
        all_labels, all_preds, target_names=CLASS_NAMES, digits=4
    )
    with open(f'classification_report_fold_{fold_idx+1}.txt', 'w', encoding='utf-8') as f:
        f.write(report)

    print(f"\nFold {fold_idx+1} Final Metrics:")
    print(f"Accuracy: {overall_acc:.4f} | Precision: {avg_precision:.4f} | "
          f"Recall: {avg_recall:.4f} | F1: {avg_f1:.4f}")

    return {
        'accuracy': overall_acc,
        'precision': avg_precision,
        'recall': avg_recall,
        'f1': avg_f1,
        'best_val_acc': best_val_acc,
        'best_epoch': best_epoch
    }


if __name__ == "__main__":
    # 1. 加载数据集
    data = np.load(DATA_PATH, allow_pickle=True).item()
    X = data["features"]
    y = data["labels"]

    print("Original Data shape:", X.shape)
    print("Label range:", y.min(), "~", y.max())

    # 检查数据维度并添加通道维
    assert len(X.shape) == 3, f"Expected 3D features (samples, H, W), got {X.shape}"
    X = np.expand_dims(X, axis=1)  # (samples, 1, H, W)

    # 2. 初始化K-Fold
    kf = KFold(n_splits=K_FOLDS, shuffle=True, random_state=42)  # shuffle=True保证数据随机划分
    fold_metrics = []  # 存储每折的指标

    # 3. 遍历每折训练
    for fold_idx, (train_idx, val_idx) in enumerate(kf.split(X)):
        fold_result = train_single_fold(X, y, train_idx, val_idx, fold_idx)
        fold_metrics.append(fold_result)

    # 4. 计算K折平均指标
    avg_acc = np.mean([m['accuracy'] for m in fold_metrics])
    avg_precision = np.mean([m['precision'] for m in fold_metrics])
    avg_recall = np.mean([m['recall'] for m in fold_metrics])
    avg_f1 = np.mean([m['f1'] for m in fold_metrics])
    avg_best_val_acc = np.mean([m['best_val_acc'] for m in fold_metrics])

    print("\n===== K-Fold Cross Validation Summary =====")
    print(f"Number of Folds: {K_FOLDS}")
    print(f"Average Accuracy: {avg_acc:.4f} (+/- {np.std([m['accuracy'] for m in fold_metrics]):.4f})")
    print(f"Average Precision: {avg_precision:.4f} (+/- {np.std([m['precision'] for m in fold_metrics]):.4f})")
    print(f"Average Recall: {avg_recall:.4f} (+/- {np.std([m['recall'] for m in fold_metrics]):.4f})")
    print(f"Average F1 Score: {avg_f1:.4f} (+/- {np.std([m['f1'] for m in fold_metrics]):.4f})")
    print(f"Average Best Val Acc: {avg_best_val_acc:.4f}")

    # 5. 保存K折汇总结果
    summary = {
        'k_folds': K_FOLDS,
        'avg_accuracy': avg_acc,
        'avg_precision': avg_precision,
        'avg_recall': avg_recall,
        'avg_f1': avg_f1,
        'fold_details': fold_metrics
    }
    np.save('kfold_summary.npy', summary)
    print("\nK-Fold summary saved to: kfold_summary.npy")