# Raw_Code_portfolio
A collection of project code that completes various data analysis tasks. The datasets are not included as some are not publicly available and should not be shared. Code is in either R or Python.

Code is specialized to specific datasets. Projects are grouped into individual folders as some projects consist of many different code files due to the nature of the analysis (some scripts may take several hours to run, and separating scripts allowed for piecewise analysis).

## FF_NN_classification_and_regression_practice

This file is a Python notebook that contains code which imports two datasets from Kaggle, pre-processes those datasets, and creates two models. The diabetes dataset is a classification problem and the cancer dataset is a regression problem. These datasets are modeled using simple fully connected, feed forward neural networks built using the Keras package. 

The cancer dataset successfully produces a strong model which reports low MSE on both the training and testing data. The hyperparameter settings are those which resulted in a good balance between further lowering the MSE, minimizing overfitting, and low computation time. 

The diabetes dataset seeks to model history of gestational diabetes based on a number of common health-related covariates. This dataset has proved to be challenging. Through many different iterations and data transformations, this dataset could not result in accuracy very far from 50%, indicating that while we could get increasingly good accuracy on the training data by adding training epochs and depth to the network, the dataset itself appears to just contain noise. This was further confirmed by both consultation with colleagues working on the same problem as well as the course instructor who further attempted fitting the dataset to several non-neural network machine learning models. This dataset warrants further investigation to find a good model that can accurately classify datapoints. 

