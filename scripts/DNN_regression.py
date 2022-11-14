import numpy as np
import pandas
import tensorflow as tf
from tensorflow.keras.models import Sequential
from tensorflow.keras.layers import Dense, Dropout
from sklearn.model_selection import KFold
import os
from sklearn import metrics
from sklearn.metrics import r2_score
import sys

print("DNN modeling...")
filename = sys.argv[1]
output_path = sys.argv[2]

df = pandas.read_table(filename, delim_whitespace=True, header="infer")

dataset = df.values
X = df.iloc[:, 3:df.shape[1]]
Y = df.iloc[:, 2]

kf = KFold(n_splits=5, shuffle=True, random_state=0)
X_train = []
X_test = []
Y_train = []
Y_test = []

for train_index, test_index in kf.split(X):
    #print(X.iloc[train_index].shape)
    X_train.append(X.iloc[train_index])
    X_test.append(X.iloc[test_index])
    Y_train.append(Y.iloc[train_index])
    Y_test.append(Y.iloc[test_index])

def baseline_model():
    model = Sequential()
    model.add(Dense(128, activation='relu'))
    model.add(Dense(512, activation='relu',))
    model.add(Dropout(0.5))
    model.add(Dense(256, activation='relu', ))
    model.add(Dropout(0.5))
    model.add(Dense(1, activation='linear'))
    return model

tf.random.set_seed(0)

true_y = []
predict_y = []
MAE = []
r2_s = []

for k in range(0, 5):
    print("**************************", k, "**************************")
    imodel = baseline_model()
    imodel.compile(optimizer="adam", loss='mae')
    history = imodel.fit(X_train[k].values, Y_train[k].values, epochs=300, batch_size=256, verbose=2)
    true_y = true_y+list(Y_test[k].values)
    predict = imodel.predict(X_test[k].values)
    predict = predict.flatten()
    predict_y = predict_y+list(predict)
    mae = metrics.mean_absolute_error(Y_test[k].values, predict)
    MAE.append(mae)
    r2 = r2_score(Y_test[k], predict)
    r2_s.append(r2)

print("MAE: "+str(MAE))
print("Average MAE: {} ± {}".format(np.mean(MAE), np.std(MAE)))

print("R2: "+str(r2_s))
print("Average R2: {} ± {}".format(np.mean(r2_s), np.std(r2_s)))

predict_result = {"age": true_y, "predict_age": predict_y}
predict_result = pandas.DataFrame(predict_result)
predict_result.to_csv(os.path.join(output_path,'predict_result.csv'))

np.savetxt(os.path.join(output_path,'MAE.csv'), np.array(MAE).flatten(), fmt='%f')
np.savetxt(os.path.join(output_path,'r2_score.csv'), np.array(r2_s).flatten(), fmt='%f')
print("Finished.")