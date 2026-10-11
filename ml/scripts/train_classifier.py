import os
import json
import time
import pandas as pd
import numpy as np
from sklearn.model_selection import train_test_split
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import classification_report, confusion_matrix

def train():
    base_dir = os.path.join(os.path.dirname(__file__), '..')
    dataset_dir = os.path.join(base_dir, 'dataset')
    reports_dir = os.path.join(base_dir, 'reports')
    assets_ml_dir = os.path.join(base_dir, '..', 'assets', 'ml')
    os.makedirs(reports_dir, exist_ok=True)
    os.makedirs(assets_ml_dir, exist_ok=True)

    rem_df = pd.read_csv(os.path.join(dataset_dir, 'reminder.csv'))
    dia_df = pd.read_csv(os.path.join(dataset_dir, 'diary.csv'))
    amb_df = pd.read_csv(os.path.join(dataset_dir, 'ambiguous.csv'))
    fe_df = pd.read_csv(os.path.join(dataset_dir, 'future_event.csv'))
    ot_df = pd.read_csv(os.path.join(dataset_dir, 'off_topic.csv'))

    df = pd.concat([rem_df, dia_df, amb_df, fe_df, ot_df], ignore_index=True)
    df = df.sample(frac=1.0, random_state=42).reset_index(drop=True)

    # Train (70%), Val (15%), Test (15%)
    train_val, test_df = train_test_split(df, test_size=0.15, random_state=42, stratify=df['label'])
    train_df, val_df = train_test_split(train_val, test_size=0.17647, random_state=42, stratify=train_val['label'])

    print(f"Split sizes - Train: {len(train_df)}, Val: {len(val_df)}, Test: {len(test_df)}")

    vectorizer = TfidfVectorizer(
        ngram_range=(1, 2),
        max_features=1600,
        sublinear_tf=True
    )

    X_train = vectorizer.fit_transform(train_df['text'])
    y_train = train_df['label']

    X_val = vectorizer.transform(val_df['text'])
    y_val = val_df['label']

    X_test = vectorizer.transform(test_df['text'])
    y_test = test_df['label']

    model = LogisticRegression(C=2.5, max_iter=1000, random_state=42)
    model.fit(X_train, y_train)

    # Evaluate on Test
    t0 = time.perf_counter()
    test_preds = model.predict(X_test)
    inference_time = (time.perf_counter() - t0) / len(test_df) * 1000 # ms per item

    classes = list(model.classes_)
    report = classification_report(y_test, test_preds, digits=4, output_dict=True)
    cm = confusion_matrix(y_test, test_preds, labels=classes)

    # Measure Diary -> Reminder false positive rate
    diary_idx = classes.index('diary')
    reminder_idx = classes.index('reminder')
    diary_total = int(np.sum(cm[diary_idx]))
    diary_as_reminder = int(cm[diary_idx][reminder_idx])
    false_reminder_rate = (diary_as_reminder / diary_total) if diary_total > 0 else 0.0

    print("\n--- Test Set Classification Report ---")
    print(classification_report(y_test, test_preds, digits=4))
    print("Confusion Matrix (classes:", classes, "):")
    print(cm)
    print(f"False Reminder Rate (Diary -> Reminder): {false_reminder_rate * 100:.2f}%")
    print(f"Avg Inference Latency: {inference_time:.3f} ms per sample")

    # Generate evaluation.md
    rows_md = ""
    for c in classes:
        p = report[c]['precision'] * 100
        r = report[c]['recall'] * 100
        f1 = report[c]['f1-score'] * 100
        sup = report[c]['support']
        rows_md += f"| **{c.capitalize()}** | {p:.2f}% | {r:.2f}% | {f1:.2f}% | {sup} |\n"

    md_content = f"""# Remindly — Local Intent Classifier Evaluation Report

- **Model Version**: 2.0.0 (Production Held-Out Evaluation)
- **Architecture**: Sublinear TF-IDF (1-2 ngrams, 1600 vocabulary features) + Multiclass Logistic Regression
- **Target Classes**: `{classes}`
- **Dataset Version**: v2.0.0 (Total: {len(df)}, Train: {len(train_df)}, Val: {len(val_df)}, Test: {len(test_df)})
- **Accuracy**: {report['accuracy'] * 100:.2f}%
- **Macro F1**: {report['macro avg']['f1-score'] * 100:.2f}%
- **Weighted F1**: {report['weighted avg']['f1-score'] * 100:.2f}%
- **False Reminder Rate (Diary → Reminder)**: {false_reminder_rate * 100:.2f}%
- **Average Inference Latency**: {inference_time:.3f} ms / prediction

## Per-Class Metrics

| Class | Precision | Recall | F1-Score | Support |
|---|---|---|---|---|
{rows_md}
## Confusion Matrix

Classes order: `{classes}`

```
{cm}
```

## Thresholding & Routing Rules

- **Score >= 0.85**: High confidence → automatic classification / streamlined confirmation preview.
- **0.60 <= Score < 0.85**: Medium confidence → confirmation preview shown to user.
- **Score < 0.60** or **Ambiguous**: Low confidence → clarification requested.
- **future_event**: Prompts the user: *"I noticed this is a future event on [Date] at [Time]. Would you like to create a reminder?"*
- **off_topic**: Prompts the user: *"This doesn't appear to be a diary entry. Would you like to save it in your diary anyway?"*

## Zero-Cloud Local Packaging

The model vocabulary, inverse document frequencies (IDF), and logistic regression weight matrices are exported into `assets/ml/intent_weights.json` for deterministic, zero-dependency, 100% on-device offline mobile execution.
"""
    with open(os.path.join(reports_dir, 'evaluation.md'), 'w', encoding='utf-8') as f:
        f.write(md_content)

    # Export model weights for Flutter Dart inference
    vocab = {str(k): int(v) for k, v in vectorizer.vocabulary_.items()}
    idf = [float(x) for x in vectorizer.idf_]
    coef = [[float(val) for val in row] for row in model.coef_]
    intercept = [float(x) for x in model.intercept_]

    model_payload = {
        "version": "2.0.0",
        "classes": [str(c) for c in classes],
        "vocabulary": vocab,
        "idf": idf,
        "coefficients": coef,
        "intercept": intercept,
        "ngram_range": [1, 2]
    }

    output_path = os.path.join(assets_ml_dir, 'intent_weights.json')
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(model_payload, f, indent=2)

    with open(os.path.join(base_dir, 'model', 'intent_weights.json'), 'w', encoding='utf-8') as f:
        json.dump(model_payload, f, indent=2)

    print(f"\nModel exported successfully to {output_path} ({os.path.getsize(output_path)} bytes)")

if __name__ == '__main__':
    train()
