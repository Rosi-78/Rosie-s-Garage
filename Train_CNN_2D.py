import numpy as np
import torch
import torch.nn as nn
import torch.optim as optim
from torch.utils.data import DataLoader, TensorDataset
from sklearn.model_selection import train_test_split
from sklearn.metrics import (
    classification_report, confusion_matrix, accuracy_score,
    precision_recall_fscore_support
)
import matplotlib.pyplot as plt
import seaborn as sns

plt.rcParams['font.family'] = 'Arial'
plt.rcParams['axes.unicode_minus'] = False  # 解决负号显示问题

# 配置参数
DATA_PATH = "audio_10class_dataset.npy"
BATCH_SIZE = 16
EPOCHS = 50
LR = 0.001
NUM_CLASSES = 10
CLASS_NAMES = [f"Class {i}" for i in range(NUM_CLASSES)]
BEST_MODEL_PATH = "best_simple_cnn_10class.pth"  # 最优模型保存路径


class SimpleCNN(nn.Module):
    def __init__(self, input_shape):
        super().__init__()
        # 动态计算卷积输出维度
        self.conv1 = nn.Conv2d(1, 16, 3, padding=1)
        self.pool = nn.MaxPool2d(2)
        self.conv2 = nn.Conv2d(16, 32, 3, padding=1)

        # 计算卷积层输出维度
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


def plot_train_history(train_losses, train_accs, val_losses, val_accs):
    """Plot training/validation loss and accuracy curves (English)"""
    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(15, 5))

    # Loss curve
    ax1.plot(range(1, EPOCHS + 1), train_losses, label='Training Loss', color='blue', linewidth=2)
    ax1.plot(range(1, EPOCHS + 1), val_losses, label='Validation Loss', color='red', linewidth=2)
    ax1.set_xlabel('Epoch')
    ax1.set_ylabel('Loss')
    ax1.set_title('Training/Validation Loss Curve')
    ax1.legend()
    ax1.grid(alpha=0.3)

    # Accuracy curve
    ax2.plot(range(1, EPOCHS + 1), train_accs, label='Training Accuracy', color='blue', linewidth=2)
    ax2.plot(range(1, EPOCHS + 1), val_accs, label='Validation Accuracy', color='red', linewidth=2)
    ax2.set_xlabel('Epoch')
    ax2.set_ylabel('Accuracy')
    ax2.set_title('Training/Validation Accuracy Curve')
    ax2.legend()
    ax2.grid(alpha=0.3)

    plt.tight_layout()
    plt.savefig('train_history.png', dpi=300, bbox_inches='tight')
    plt.show()


def plot_confusion_matrix(y_true, y_pred, class_names):
    """Plot confusion matrix (English)"""
    cm = confusion_matrix(y_true, y_pred)
    fig, ax = plt.subplots(figsize=(12, 10))

    sns.heatmap(cm, annot=True, fmt='d', cmap='Blues', ax=ax,
                xticklabels=class_names, yticklabels=class_names,
                cbar_kws={'label': 'Count'})

    ax.set_xlabel('Predicted Label')
    ax.set_ylabel('True Label')
    ax.set_title('Confusion Matrix')

    plt.xticks(rotation=45)
    plt.yticks(rotation=0)
    plt.tight_layout()
    plt.savefig('confusion_matrix.png', dpi=300, bbox_inches='tight')
    plt.show()


def plot_class_metrics(y_true, y_pred, class_names):
    """Plot per-class metrics (precision/recall/F1/accuracy) in English"""
    # Calculate metrics
    precision, recall, f1, _ = precision_recall_fscore_support(
        y_true, y_pred, average=None, labels=range(len(class_names))
    )
    accuracy_per_class = []
    for i in range(len(class_names)):
        mask = y_true == i
        if np.sum(mask) > 0:  # 避免空类报错
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
    ax1.set_title('Per-Class Accuracy')
    ax1.set_xticks(x)
    ax1.set_xticklabels(class_names, rotation=45)
    ax1.grid(alpha=0.3, axis='y')
    ax1.set_ylim(0, 1.05)  # 固定y轴范围

    # Precision per class
    ax2.bar(x, precision, width, color='#ff7f0e', alpha=0.8)
    ax2.set_xlabel('Class')
    ax2.set_ylabel('Precision')
    ax2.set_title('Per-Class Precision')
    ax2.set_xticks(x)
    ax2.set_xticklabels(class_names, rotation=45)
    ax2.grid(alpha=0.3, axis='y')
    ax2.set_ylim(0, 1.05)

    # Recall per class
    ax3.bar(x, recall, width, color='#2ca02c', alpha=0.8)
    ax3.set_xlabel('Class')
    ax3.set_ylabel('Recall')
    ax3.set_title('Per-Class Recall')
    ax3.set_xticks(x)
    ax3.set_xticklabels(class_names, rotation=45)
    ax3.grid(alpha=0.3, axis='y')
    ax3.set_ylim(0, 1.05)

    # F1 Score per class
    ax4.bar(x, f1, width, color='#d62728', alpha=0.8)
    ax4.set_xlabel('Class')
    ax4.set_ylabel('F1 Score')
    ax4.set_title('Per-Class F1 Score')
    ax4.set_xticks(x)
    ax4.set_xticklabels(class_names, rotation=45)
    ax4.grid(alpha=0.3, axis='y')
    ax4.set_ylim(0, 1.05)

    plt.tight_layout()
    plt.savefig('class_metrics.png', dpi=300, bbox_inches='tight')
    plt.show()


if __name__ == "__main__":
    # 1. Load dataset
    data = np.load(DATA_PATH, allow_pickle=True).item()
    X = data["features"]
    y = data["labels"]

    print("Data shape:", X.shape)
    print("Label range:", y.min(), "~", y.max())

    # Check data validity
    assert len(X.shape) == 3, f"Expected 3D features (samples, H, W), got {X.shape}"
    X = np.expand_dims(X, axis=1)  # Add channel dimension (samples, 1, H, W)

    # Split dataset
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, stratify=y, random_state=42
    )

    # Create DataLoader
    train_dataset = TensorDataset(torch.FloatTensor(X_train), torch.LongTensor(y_train))
    test_dataset = TensorDataset(torch.FloatTensor(X_test), torch.LongTensor(y_test))

    train_loader = DataLoader(train_dataset, batch_size=BATCH_SIZE, shuffle=True)
    test_loader = DataLoader(test_dataset, batch_size=BATCH_SIZE, shuffle=False)

    # Device configuration
    device = "cuda" if torch.cuda.is_available() else "cpu"
    print(f"Using device: {device}")

    # Initialize model (dynamic input shape)
    input_shape = X_train[0].shape  # (1, H, W)
    model = SimpleCNN(input_shape).to(device)
    criterion = nn.CrossEntropyLoss()
    optimizer = optim.Adam(model.parameters(), lr=LR)

    # Training history and best model tracking
    train_losses = []
    train_accs = []
    val_losses = []
    val_accs = []
    best_val_acc = 0.0  # Track best validation accuracy
    best_epoch = 0  # Track epoch of best model

    print("\nStart training...")
    for epoch in range(EPOCHS):
        # Training phase
        model.train()
        train_loss = 0
        train_correct = 0
        train_total = 0

        for data, label in train_loader:
            data, label = data.to(device), label.to(device)
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

        # Validation phase
        model.eval()
        val_loss = 0
        val_correct = 0
        val_total = 0
        all_preds = []
        all_labels = []

        with torch.no_grad():
            for data, label in test_loader:
                data, label = data.to(device), label.to(device)
                output = model(data)
                loss = criterion(output, label)
                val_loss += loss.item()

                pred = output.argmax(dim=1)
                val_correct += (pred == label).sum().item()
                val_total += label.size(0)

                all_preds.extend(pred.cpu().numpy())
                all_labels.extend(label.cpu().numpy())

        val_epoch_loss = val_loss / len(test_loader)
        val_epoch_acc = val_correct / val_total
        val_losses.append(val_epoch_loss)
        val_accs.append(val_epoch_acc)

        # Save best model (based on validation accuracy)
        if val_epoch_acc > best_val_acc:
            best_val_acc = val_epoch_acc
            best_epoch = epoch + 1
            torch.save({
                'epoch': epoch + 1,
                'model_state_dict': model.state_dict(),
                'optimizer_state_dict': optimizer.state_dict(),
                'val_accuracy': val_epoch_acc,
                'train_loss': train_epoch_loss,
                'val_loss': val_epoch_loss
            }, BEST_MODEL_PATH)

        # Print epoch info
        print(f"Epoch {epoch + 1:2d}/{EPOCHS} | "
              f"Train Loss: {train_epoch_loss:.4f} | Train Acc: {train_epoch_acc:.2%} | "
              f"Val Loss: {val_epoch_loss:.4f} | Val Acc: {val_epoch_acc:.2%} | "
              f"Best Val Acc: {best_val_acc:.2%} (Epoch {best_epoch})")

    print("\n===== Training Completed =====")

    # 1. Classification report
    print("\n1. Detailed Classification Report:")
    report = classification_report(
        all_labels, all_preds, target_names=CLASS_NAMES, digits=4
    )
    print(report)
    with open('classification_report.txt', 'w', encoding='utf-8') as f:
        f.write(report)

    # 2. Plot training history
    print("\n2. Plotting Training History...")
    plot_train_history(train_losses, train_accs, val_losses, val_accs)

    # 3. Plot confusion matrix
    print("\n3. Plotting Confusion Matrix...")
    plot_confusion_matrix(all_labels, all_preds, CLASS_NAMES)

    # 4. Plot per-class metrics
    print("\n4. Plotting Per-Class Metrics...")
    plot_class_metrics(all_labels, all_preds, CLASS_NAMES)

    # 5. Save final model
    torch.save(model.state_dict(), 'final_simple_cnn_10class.pth')
    print(f"\n5. Final model saved as: final_simple_cnn_10class.pth")
    print(f"   Best model saved as: {BEST_MODEL_PATH} (Val Acc: {best_val_acc:.4f}, Epoch {best_epoch})")

    # 6. Overall metrics
    overall_acc = accuracy_score(all_labels, all_preds)
    avg_precision, avg_recall, avg_f1, _ = precision_recall_fscore_support(
        all_labels, all_preds, average='weighted'
    )
    print(f"\nOverall Evaluation Metrics:")
    print(f"Weighted Average Precision: {avg_precision:.4f}")
    print(f"Weighted Average Recall: {avg_recall:.4f}")
    print(f"Weighted Average F1 Score: {avg_f1:.4f}")
    print(f"Overall Accuracy: {overall_acc:.4f}")