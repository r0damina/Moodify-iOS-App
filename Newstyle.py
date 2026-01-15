import sys
sys.path.append('/Users/rawandsalameh/emotion-recognition-using-speech')

import librosa
import coremltools
from data_extractor import load_data
from utils import extract_feature, AVAILABLE_EMOTIONS
from create_csv import write_emodb_csv, write_tess_ravdess_csv, write_custom_csv
import numpy as np
import pandas as pd
import pickle
import joblib
import tqdm
import os
from sklearn.metrics import accuracy_score, fbeta_score, mean_squared_error, confusion_matrix, classification_report
import matplotlib.pyplot as plt
from time import time
from utils import get_best_estimators, get_audio_config
import random
from sklearn.linear_model import LogisticRegression
from sklearn.svm import SVC

#%% Globals to retain state
state = {
    "emotions": ["sad", "happy"],
    "features": ["mfcc", "chroma", "mel"],
    "audio_config": None,
    "classification": True,
    "balance": True,
    "verbose": 1,
    "debug": False,  # Enable/Disable debug prints
    "tess_ravdess": True,
    "emodb": True,
    "custom_db": True,
    "override_csv": True,
    "train_desc_files": [],
    "test_desc_files": [],
    "tess_ravdess_name": "tess_ravdess.csv",
    "emodb_name": "emodb.csv",
    "custom_db_name": "custom.csv",
    "model": None,
    "data_loaded": False,
    "model_trained": False,
    "X_train": None,
    "X_test": None,
    "y_train": None,
    "y_test": None,
    "train_audio_paths": None,
    "test_audio_paths": None
}

#%% Print debug messages if debugging is enabled.
def debug_print(message):
    if state["debug"]:
        print("[DEBUG]", message)

#%% Set metadata filenames for train and test descriptions.
def _set_metadata_filenames():
    train_desc_files, test_desc_files = [], []
    if state["tess_ravdess"]:
        train_desc_files.append(f"train_{state['tess_ravdess_name']}")
        test_desc_files.append(f"test_{state['tess_ravdess_name']}")
    if state["emodb"]:
        train_desc_files.append(f"train_{state['emodb_name']}")
        test_desc_files.append(f"test_{state['emodb_name']}")
    if state["custom_db"]:
        train_desc_files.append(f"train_{state['custom_db_name']}")
        test_desc_files.append(f"test_{state['custom_db_name']}")
    state["train_desc_files"] = train_desc_files
    state["test_desc_files"] = test_desc_files

#%% Ensure that the specified emotions are valid.
def _verify_emotions():
    for emotion in state["emotions"]:
        assert emotion in AVAILABLE_EMOTIONS, f"Emotion {emotion} is not recognized."

#%% Write metadata CSVs based on the current settings.
def write_csv():
    for train_csv_file, test_csv_file in zip(state["train_desc_files"], state["test_desc_files"]):
        if os.path.isfile(train_csv_file) and os.path.isfile(test_csv_file):
            if not state["override_csv"]:
                continue
        if state["emodb_name"] in train_csv_file:
            write_emodb_csv(state["emotions"], train_name=train_csv_file, test_name=test_csv_file, verbose=state["verbose"])
        elif state["tess_ravdess_name"] in train_csv_file:
            write_tess_ravdess_csv(state["emotions"], train_name=train_csv_file, test_name=test_csv_file, verbose=state["verbose"])
        elif state["custom_db_name"] in train_csv_file:
            write_custom_csv(emotions=state["emotions"], train_name=train_csv_file, test_name=test_csv_file, verbose=state["verbose"])

#%% Load and preprocess the dataset.
def load_data_from_state(state):
    emotions = state.get("emotions", ['sad', 'happy'])
    result = load_data(state["train_desc_files"], state["test_desc_files"], state["audio_config"],
                       state["classification"], shuffle=True, balance=True, emotions=emotions)

    state.update({
        "X_train": result['X_train'],
        "X_test": result['X_test'],
        "y_train": result['y_train'],
        "y_test": result['y_test'],
        "train_audio_paths": result['train_audio_paths'],
        "test_audio_paths": result['test_audio_paths'],
        "balance": result['balance'],
        "data_loaded": True  # Mark data as loaded
    })

    # Debugging print statements
    print(f"[INFO] Features extracted: Train shape {state['X_train'].shape}, Test shape {state['X_test'].shape}")
    print(f"[INFO] Input features shape: {state['X_train'].shape[1]}")

#%% Train the provided model.
def train(model=None, verbose=1):
    """Function to train the model."""
    if not state["data_loaded"]:
        load_data_from_state(state)  # Load the data using the new function

    if state['X_train'] is None or state['y_train'] is None:
        print("[ERROR] Training data is not loaded properly!")
        return

    # Print the shapes of X_train and y_train to check the data
    print(f"X_train shape: {state['X_train'].shape}")
    print(f"y_train shape: {len(state['y_train'])}")

    if model is None:
        model = state["model"]

    # Train the model
    model.fit(state['X_train'], state['y_train'])  # Fit the model with the loaded data
    state["model_trained"] = True  # Mark model as trained
    if verbose:
        print("[INFO] Model training complete.")

#%% Predict the emotion for a given audio file.
def predict(audio_path):
    debug_print(f"Predicting emotion for audio file: {audio_path}")
    feature = extract_feature(audio_path, **state["audio_config"]).reshape(1, -1)
    prediction = state["model"].predict(feature)[0]
    print(f"[INFO] Prediction: {prediction}")
    return prediction

#%% Predict the probabilities for each emotion for a given audio file.
def predict_proba(audio_path):
    if state["classification"]:
        debug_print(f"Predicting probabilities for audio file: {audio_path}")
        feature = extract_feature(audio_path, **state["audio_config"]).reshape(1, -1)
        proba = state["model"].predict_proba(feature)[0]  # Use the SVC predict_proba
        result = dict(zip(state["model"].classes_, proba))
        print(f"[INFO] Predicted probabilities: {result}")
        return result
    else:
        raise NotImplementedError("Probability prediction is only for classification tasks.")

#%% Evaluate the model's performance on test data.
def evaluate():
    if not state["model_trained"]:
        raise RuntimeError("Model has not been trained yet.")
    y_pred = state["model"].predict(state["X_test"])
    
    # Evaluation metrics
    accuracy = accuracy_score(state["y_test"], y_pred)
    f1_score = fbeta_score(state["y_test"], y_pred, beta=1, average='weighted')
    print(f"[INFO] Test Accuracy: {accuracy:.2f}")
    print(f"[INFO] Test F1 Score (weighted): {f1_score:.2f}")
    return accuracy, f1_score

#%% Generate a confusion matrix.
def confusion_matrix_report(percentage=True, labeled=True):
    y_pred = state["model"].predict(state["X_test"])
    matrix = confusion_matrix(state["y_test"], y_pred, labels=state["emotions"]).astype(np.float32)
    if percentage:
        matrix = (matrix.T / matrix.sum(axis=1)).T * 100
    if labeled:
        matrix = pd.DataFrame(matrix, index=[f"true_{e}" for e in state["emotions"]],
                              columns=[f"predicted_{e}" for e in state["emotions"]])
    print("[INFO] Confusion matrix:")
    print(matrix)
    return matrix

#%% Plot the confusion matrix.
def confusion_matrix_plot():
    matrix = confusion_matrix_report(percentage=True, labeled=True)
    plt.imshow(matrix, cmap="Blues", interpolation="nearest")
    plt.colorbar()
    plt.title("Confusion Matrix")
    plt.xlabel("Predicted Label")
    plt.ylabel("True Label")
    plt.show()

# Initialize the state and audio configuration
_verify_emotions()
state["audio_config"] = get_audio_config(state["features"])
_set_metadata_filenames()
write_csv()

# Initialize the model
state["model"] = SVC(probability=True)  # Enable probability predictions for SVC

# Train the model
train(state["model"])  # This will train the initialized SVC model

# Save the trained model using joblib
model_filename = "Speechrec_SVC.pkl"
joblib.dump(state["model"], model_filename)
print(f"[INFO] Model saved as {model_filename}.")

# Define feature names based on the audio config
def convert_to_coreml():
    
    import coremltools
    import joblib

    # Load the trained model
    model_filename = "Speechrec_SVC.pkl"
    trained_model = joblib.load(model_filename)

    try:
        # Perform the conversion with minimal arguments
        coreml_model = coremltools.converters.sklearn.convert(trained_model)

        # Save the CoreML model
        coreml_model.save("MLSpeech_SVC.mlmodel")
        print("[INFO] CoreML model saved as MLSpeech_SVC.mlmodel")
    except Exception as e:
        print(f"[ERROR] CoreML conversion failed: {str(e)}")
        # Save the CoreML model
        coreml_model.save("SpeechML_SVC.mlmodel")
        print("[INFO] CoreML model saved as MLSpeech_SVC.mlmodel")
    except Exception as e:
        print(f"[ERROR] CoreML conversion failed: {str(e)}")



# Call the conversion function
convert_to_coreml()


coreml_model = coremltools.models.MLModel("MLSpeech_SVC.mlmodel")
print(coreml_model.input_description)
print(coreml_model.output_description)

# Evaluate and print metrics
accuracy, f1_score = evaluate()

# Plot confusion matrix
confusion_matrix_plot()