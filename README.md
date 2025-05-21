# Raw_Code_portfolio
A collection of project code that completes various data analysis tasks. The datasets are not included as some are not publicly available and should not be shared. Code is in either R or Python.

Code is specialized to specific datasets. Projects are grouped into individual folders as some projects consist of many different code files due to the nature of the analysis (some scripts may take several hours to run, and separating scripts allowed for piecewise analysis).

## FF_NN_classification_and_regression_practice

This file is a Python notebook that contains code which imports two datasets from Kaggle, pre-processes those datasets, and creates two models. The diabetes dataset is a classification problem and the cancer dataset is a regression problem. These datasets are modeled using simple fully connected, feed forward neural networks built using the Keras package. 

The cancer dataset successfully produces a strong model which reports low MSE on both the training and testing data. The hyperparameter settings are those which resulted in a good balance between further lowering the MSE, minimizing overfitting, and low computation time. 

The diabetes dataset seeks to model history of gestational diabetes based on a number of common health-related covariates. This dataset has proved to be challenging. Through many different iterations and data transformations, this dataset could not result in accuracy very far from 50%, indicating that while we could get increasingly good accuracy on the training data by adding training epochs and depth to the network, the dataset itself appears to just contain noise. This was further confirmed by both consultation with colleagues working on the same problem as well as the course instructor who further attempted fitting the dataset to several non-neural network machine learning models. This dataset warrants further investigation to find a good model that can accurately classify datapoints. 

## STAT_760_HW6_FFNN

This file is a Python notebook written using Google Colab. Included is a function which takes in a dataset and models the output variable (currently only supporting 1 dimensional output) via a fully connected feed forward neural network. This function was written by hand and employs the gradient descent via backpropogation algorithm for training parameters. It currently supports changes in the following hyperparameters: learning rate, batch size, maximum epochs, minimum MSE change between epochs to exit, number of hidden alyers and number of neurons in each layer, and a few activation functions. It applies the same activation function to each hidden layer. This modeling algorithm has shown promise in accurately predicting output in regression problems, and does not employ any regularizers or other optimization algorithms. 

## Neural_Network_Final_Project

This file is a jupyter notebook that contains preprocessing and experimentation to find a model that can sucessfully classify images of animals into one of 15 classes. Included are model diagnostics, architectures, and narrative. The final model is a transfer learning model built on top of MobileNetV2, and achieved very high accuracy (97.3%) on training data with some minor overfitting, resulting in 94% accuracy in testing data. Model preprocessing included checking image for color, checking the set for image size, importing the dataset, creating a random image generator that will generate slight variations on the iamges on the fly during training to help with generalization, and splitting and scaling of the dataset. The dataset was pulled from Kaggle (https://www.kaggle.com/datasets/likhon148/animal-data). I believe that had I had more computing power at my disposal I could have created a stronger model that did not use transfer learning, but given the circumstances transfer learning seemed the best way to go to reduce resource useage.

## Stochastic Model to Track Recessions

This collection of files is a project from a stochastic processes and simulation course. In this project, I sought to create a Markov chain model that can predict future  recessions using previous recessions and the bond rates as a time-series. This was modeled as a 4 state discrete time Markov chain. The transitision matrix was calculated using Python, and a stationary distribution and rate of convergence was found for this Markov process, representing the time anticipated to be spent in each state of the chain after a burn-in period. All computations were developed in Python, but the original source code file is lost, in its place is a pdf of the code that was submitted alongside the project write-up which includes introduction, methods, results, and discussions.
