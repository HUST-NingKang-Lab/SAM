# SAM

Skin age model

## Introduction

SAMs are used for assessing the skin state from phenotypic and microbial perspectives.

The introduction and online version of the SAM have been deposited to the webset:

https://hustmoon.shinyapps.io/skin_age/

## Installation

```shell
# clone this repository
git clone https://github.com/HUST-NingKang-Lab/SAM.git
cd SAM

# configure environment using environment.yaml
conda install mamba -n base -c conda-forge -y
mamba env create -f environment.yml
conda activate SAM
```

## Usage

We have two modes: 1) DNN: deep neural network; 2) RF: random forest regression.

You can control the mode by set the parameter `-m`

**DNN mode**

```shell
python SAM.py -m DNN -i input_path -o output_path

#Using the example files:
python SAM.py -m DNN -i ./DNN_regression/input -o ./DNN_regression/output
```

**RF mode**

```shell
python SAM.py -m RF -i input_path -o output_path

#Using the example files:
python SAM.py -m RF -i ./RF_regression/input -o ./RF_regression/output
```

