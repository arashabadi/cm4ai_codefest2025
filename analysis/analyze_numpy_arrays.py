#!/usr/bin/env python3
"""
Quick script to load and display numpy arrays from HPA cell segmentation results.
"""

import numpy as np
import matplotlib.pyplot as plt
from pathlib import Path
import os

def main():
    # Define the segmentation results directory
    results_dir = Path('segmentation_results')
    
    # Get all numpy prediction files
    npy_files = list(results_dir.glob('*_prediction.npy'))
    print(f"Found {len(npy_files)} numpy prediction files:")
    for file in npy_files:
        print(f"  - {file.name}")
    
    print("\n" + "="*80)
    
    # Load and analyze each numpy array
    for npy_file in npy_files:
        print(f"\nAnalyzing: {npy_file.name}")
        print("-" * 60)
        
        try:
            # Load the numpy array
            prediction = np.load(npy_file)
            
            # Print basic information
            print(f"Array shape: {prediction.shape}")
            print(f"Data type: {prediction.dtype}")
            print(f"Min value: {prediction.min():.6f}")
            print(f"Max value: {prediction.max():.6f}")
            print(f"Mean value: {prediction.mean():.6f}")
            print(f"Standard deviation: {prediction.std():.6f}")
            
            # Check for unique values
            unique_vals = np.unique(prediction)
            print(f"Unique values: {unique_vals}")
            print(f"Number of unique values: {len(unique_vals)}")
            
            # Display the array
            plt.figure(figsize=(15, 5))
            
            # Original prediction
            plt.subplot(1, 3, 1)
            plt.imshow(prediction, cmap='viridis')
            plt.title(f'{npy_file.stem}\nPrediction Array')
            plt.colorbar(label='Prediction Value')
            plt.axis('off')
            
            # Histogram of values
            plt.subplot(1, 3, 2)
            plt.hist(prediction.flatten(), bins=50, alpha=0.7, edgecolor='black')
            plt.title('Histogram of Prediction Values')
            plt.xlabel('Prediction Value')
            plt.ylabel('Frequency')
            plt.grid(True, alpha=0.3)
            
            # Binary threshold view
            plt.subplot(1, 3, 3)
            if prediction.max() <= 1.0:
                # Likely probability values, show threshold at 0.5
                binary_view = (prediction > 0.5).astype(np.uint8)
                plt.imshow(binary_view, cmap='gray')
                plt.title('Binary Threshold (0.5)')
            else:
                # Likely raw scores, show threshold at mean
                threshold = prediction.mean()
                binary_view = (prediction > threshold).astype(np.uint8)
                plt.imshow(binary_view, cmap='gray')
                plt.title(f'Binary Threshold (mean: {threshold:.3f})')
            plt.axis('off')
            
            plt.tight_layout()
            plt.show()
            
        except Exception as e:
            print(f"Error loading {npy_file.name}: {e}")
    
    # Summary of all arrays
    print("\n" + "="*80)
    print("SUMMARY OF ALL ARRAYS:")
    print("="*80)
    
    all_predictions = {}
    for npy_file in npy_files:
        try:
            prediction = np.load(npy_file)
            all_predictions[npy_file.stem] = prediction
        except Exception as e:
            print(f"Error loading {npy_file.name}: {e}")
    
    print(f"\nSuccessfully loaded {len(all_predictions)} prediction arrays")
    
    # Create a summary table
    print("\nSummary Statistics:")
    print("-" * 100)
    print(f"{'Filename':<50} {'Shape':<20} {'Min':<12} {'Max':<12} {'Mean':<12}")
    print("-" * 100)
    
    for name, pred in all_predictions.items():
        print(f"{name:<50} {str(pred.shape):<20} {pred.min():<12.4f} {pred.max():<12.4f} {pred.mean():<12.4f}")

if __name__ == "__main__":
    main()
