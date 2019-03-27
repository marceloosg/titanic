# Introduction
The purpose of this repository is to examine the crash data from a ship accident and (
build a predictive model for the survival probability of each
passenger.
This repository consists in 6 main files:
* data/train.csv  - training data
* data/test.csv - test data (no target column)
* data/variables.txt - cookbook explaining the meaning of each variable in the dataset
* data/feature_engineering.R - helper functions for training models and extracting features 
* data/exploratory.Rmd - exploratory analysis notebook
* data/exploratory.Rmd.nb.html - output of the notobook

# Exploratory Analysis
After conducting a series of cleaning and data manipulations two main models were built and it's performance analysed.

## LDA model:
  Linear Discriminant Analysis.
  This model were chosen due to its simplicity and resilience to overfitting. Indeed the final model proved to be less overfitted.
  The data was partitioned as follows:
    70% to the training
    30% to the validation

## RF model:
  Random Forest Model.
  This ensemble classification model is very powerfull, it can be very resistent to noise but great care must be taken to avoid overfitting.
  Even with cross-validation it is possible to overfit for an extensive grid search. A validation set is always recomended to be put aside in order to get a better assessement of its performance.
  The data was partitioned as follows:
  * 70% to a 11 fold cross-validation and 9 repetitions with an extensive grid search of the parameters (ntrees and mtry).
  * 30% to the validation 

## Remarks:
  Both LDA and RF models have similar performances on the validation set. The LDA model had the least overfit and it was chosen as the current model to use. Both the training data and the validation data was considered to train the current model. This model was applied to the test data and a ranked list of the most probable survivors was built. The survival probability drops significantly after the 150th passenger. Lacking any other information this would be the cutoff of the expected number of passenger to survive. The number of seats of life saving boats may give additional information in order to produce a better cut-off. In order to interpret the predicted probability of survival as an actual probability a probability calibration must be performed.
  In order to build an effective security policy additional analysis must be performed, such as:
  * passenger clustering
  * probability calibration
  * collect crash rate data
  * elastic price-premium curve calculation