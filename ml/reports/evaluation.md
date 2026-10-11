# Remindly — Local Intent Classifier Evaluation Report

- **Model Version**: 2.0.0 (Production Held-Out Evaluation)
- **Architecture**: Sublinear TF-IDF (1-2 ngrams, 1600 vocabulary features) + Multiclass Logistic Regression
- **Target Classes**: `['ambiguous', 'diary', 'future_event', 'off_topic', 'reminder']`
- **Dataset Version**: v2.0.0 (Total: 5793, Train: 4055, Val: 869, Test: 869)
- **Accuracy**: 100.00%
- **Macro F1**: 100.00%
- **Weighted F1**: 100.00%
- **False Reminder Rate (Diary → Reminder)**: 0.00%
- **Average Inference Latency**: 0.001 ms / prediction

## Per-Class Metrics

| Class | Precision | Recall | F1-Score | Support |
|---|---|---|---|---|
| **Ambiguous** | 100.00% | 100.00% | 100.00% | 180.0 |
| **Diary** | 100.00% | 100.00% | 100.00% | 179.0 |
| **Future_event** | 100.00% | 100.00% | 100.00% | 150.0 |
| **Off_topic** | 100.00% | 100.00% | 100.00% | 150.0 |
| **Reminder** | 100.00% | 100.00% | 100.00% | 210.0 |

## Confusion Matrix

Classes order: `['ambiguous', 'diary', 'future_event', 'off_topic', 'reminder']`

```
[[180   0   0   0   0]
 [  0 179   0   0   0]
 [  0   0 150   0   0]
 [  0   0   0 150   0]
 [  0   0   0   0 210]]
```

## Thresholding & Routing Rules

- **Score >= 0.85**: High confidence → automatic classification / streamlined confirmation preview.
- **0.60 <= Score < 0.85**: Medium confidence → confirmation preview shown to user.
- **Score < 0.60** or **Ambiguous**: Low confidence → clarification requested.
- **future_event**: Prompts the user: *"I noticed this is a future event on [Date] at [Time]. Would you like to create a reminder?"*
- **off_topic**: Prompts the user: *"This doesn't appear to be a diary entry. Would you like to save it in your diary anyway?"*

## Zero-Cloud Local Packaging

The model vocabulary, inverse document frequencies (IDF), and logistic regression weight matrices are exported into `assets/ml/intent_weights.json` for deterministic, zero-dependency, 100% on-device offline mobile execution.
