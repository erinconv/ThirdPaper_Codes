import os
import matlab.engine
import numpy as np
from datetime import datetime  # Import datetime for date handling


def run_main_simulation(physiographic_results_path, params_name, output_vars):
    # Start the MATLAB engine
    eng = matlab.engine.start_matlab()

    try:
        # Add the directories containing the main_simulation.m and read_jsons.m files to the MATLAB path
        matlab_function_path = r'src'  # Path to main_simulation.m
        eng.addpath(matlab_function_path, nargout=0)
        matlab_functions_path = r'src/matlab_functions'  # Path to read_jsons.m
        eng.addpath(matlab_functions_path, nargout=0)
        matlab_calibration_function_path = r'src/calibration'  # Path to read_jsons.m
        eng.addpath(matlab_calibration_function_path, nargout=0)

        # Set execution dates
        execution = {}  # Create a dictionary to hold execution parameters
        execution['dateDebut'] = eng.datenum("1979-1-1")  # Convert to MATLAB datenum
        execution['dateFin'] = eng.datenum("2000-12-31")  # Convert to MATLAB datenum

        # Call the main_simulation function and capture the outputs
        # output_vars = eng.main_simulation(physiographic_results_path,
        #                     params_name, execution, output_vars, 0, nargout=1)
        output_vars = eng.main_calibration_flow(physiographic_results_path,
                            params_name, execution, 0, nargout=0)
    except Exception as e:
        print(f'An error occurred: {e}')
    finally:
        # Ensure the MATLAB engine is stopped
        eng.quit()
    return output_vars


def main():
    # Replace with the actual path to your physiographic results
    physiographic_results_path = r'C:\Users\Owner\Documents\rinconei\00-CEQUEAU_projects\Melezes'
    
    # Define the list of variable names to output
    # variable_names = ['debit', 'volume', 'apport', 'temperature', 
    #                   'ruiss', 'nappe', 'hypo', 'lacma', 
    #                   'radso', 'radin', 'evap', 'conv',]
    variable_names = ['debit', 'volume', 'apport', 'temperature']
    
    # Call the run_main_simulation function with the variable names
    output_vars = run_main_simulation(physiographic_results_path, 'parameters_degree_day.json', variable_names)
    
    # selected_cps = np.array([1, 2, 3])
    
    # print(np.array(selected_cps))
    a = 1


if __name__ == "__main__":
    main()
