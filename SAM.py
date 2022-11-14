#!/usr/bin/env python3
import os, sys, getopt

class sam:
    sam_path = os.path.dirname(os.path.realpath(__file__))
    DNN_regression= os.path.join(sam_path,"scripts/DNN_regression.py")
    DNN_plot = os.path.join(sam_path,"scripts/DNN_plot.R")

    RF_function = os.path.join(sam_path,"scripts/RF_function.R")
    RF_regression = os.path.join(sam_path,"scripts/RF_regression.R")

    def __init__(self, input_path, output_path):
        self.input_path = os.path.abspath(input_path)
        self.phenotype_data = os.path.join(self.input_path, "example_phenotype_data.txt")
        self.microbiota_data = os.path.join(self.input_path, "example_microbiota_data.txt")

        self.output_path = os.path.abspath(output_path)

    def DNN_model(self):
        os.makedirs(self.output_path, exist_ok=True)
        os.system("python {} {} {}".format(self.DNN_regression, self.phenotype_data, self.output_path))

        predict_result_path = os.path.join(self.output_path, "predict_result.csv")
        MAE_path = os.path.join(self.output_path, "MAE.csv")
        r2_path = os.path.join(self.output_path, "r2_score.csv")
        results_pdf = os.path.join(self.output_path, "SPA.pdf")

        os.system("Rscript {} {} {} {} {} ".format(self.DNN_plot, predict_result_path, MAE_path, r2_path, results_pdf))

    def RF_model(self):
        os.makedirs(self.output_path, exist_ok=True)
        os.system("Rscript {} {} {} {} {} ".format(self.RF_regression, self.RF_function, self.phenotype_data, self.microbiota_data,  self.output_path))

def main(argv):
    input_file = ""
    output_path = ""
    mode = ""

    try:
        opts, args = getopt.getopt(argv,"hm:i:o:",["help","model=","input_dir=","output_dir="])
    except getopt.GetoptError:
        print("python SAM.py -m <model> -i <input_dir> -o <output_dir> -h <help>")
        sys.exit(2)

    for opt, arg in opts:
        if opt in ('-h','--help'):
            print("This script is used for establishment of skin age models")
            print("-----------------------------------------")
            print("Usage:")
            print("python SAM.py -m <model> -i <input_dir> -o <output_dir> -h <help>")
            print("-----------------------------------------")
            print("-m <mode> choose DNN or RF. DNN, Deep neural network; RF, random forest ")
            print("-i <input_dir> The input directory")
            print("-o <output_dir> The output directory")
            print("-h <help> Help")
            sys.exit()
        elif opt in ("-i", "--input_dir"):
            input_file = arg
        elif opt in ("-m", "--mode"):
            mode = arg
        elif opt in ("-o", "--output_dir"):
            output_path = arg

    if mode == "DNN":
        p = sam(input_file, output_path)
        p.DNN_model()

    if mode == "RF":
        p = sam(input_file, output_path)
        p.RF_model()

if __name__ == "__main__":
    main(sys.argv[1:])




