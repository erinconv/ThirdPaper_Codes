import os
import matlab.engine
import numpy as np
from datetime import datetime
from typing import Dict, List, Any, Optional, Union
import configparser


class ConfigManager:
    """
    Class to manage configuration settings from a text file.
    This provides a centralized way to access all configurable parameters.
    """
    
    def __init__(self, config_file: str = 'simulations_setup.txt'):
        """
        Initialize the ConfigManager with a configuration file.
        
        Args:
            config_file: Path to the configuration file
        """
        self.config_file = config_file
        self.config = configparser.ConfigParser(comment_prefixes=('#'),
                                                inline_comment_prefixes=('#'))
        self.load_config()
    
    def load_config(self) -> None:
        """Load configuration from file."""
        if os.path.exists(self.config_file):
            self.config.read(self.config_file)
        else:
            raise FileNotFoundError(f"Configuration file {self.config_file} not found!")
    
    def save_config(self) -> None:
        """Save current configuration to file."""
        with open(self.config_file, 'w') as configfile:
            self.config.write(configfile, space_around_delimiters=True)
    
    def get_matlab_paths(self) -> Dict[str, str]:
        """Get MATLAB paths from configuration."""
        paths = {}
        if 'PATHS' in self.config:
            for key, value in self.config['PATHS'].items():
                paths[key] = value
        return paths
    
    def get_date_range(self) -> Dict[str, str]:
        """Get date range from configuration."""
        dates = {}
        if 'DATES' in self.config:
            dates['start_date'] = self.config['DATES'].get('start_date', '1979-1-1')
            dates['end_date'] = self.config['DATES'].get('end_date', '2000-12-31')
        return dates
    
    def get_calibration_settings(self) -> Dict[str, Any]:
        """Get calibration settings from configuration."""
        settings = {}
        if 'CALIBRATION' in self.config:
            for key, value in self.config['CALIBRATION'].items():
                settings[key] = value
        return settings
    
    def get_simulation_settings(self) -> Dict[str, Any]:
        """Get simulation settings from configuration."""
        settings = {}
        if 'SIMULATION' in self.config:
            settings = dict(self.config['SIMULATION'])
            
            # Process output_vars as a list
            if 'output_vars' in settings:
                settings['output_vars'] = [var.strip() for var in settings['output_vars'].split(',')]
            
            # Convert verbose to int if present
            if 'verbose' in settings:
                try:
                    settings['verbose'] = int(settings['verbose'])
                except ValueError:
                    settings['verbose'] = 0
        return settings
    
    def update_section(self, section: str, settings: Dict[str, Any]) -> None:
        """
        Update a section of the configuration.
        
        Args:
            section: Section name
            settings: Dictionary of settings to update
        """
        if section not in self.config:
            self.config[section] = {}
            
        for key, value in settings.items():
            # Convert lists to comma-separated strings
            if isinstance(value, list):
                self.config[section][key] = ','.join(str(item) for item in value)
            else:
                self.config[section][key] = str(value)
        
        # Save changes to file
        self.save_config()
    
    def get_value(self, section: str, key: str, default: Any = None) -> Any:
        """
        Get a specific value from the configuration.
        
        Args:
            section: Section name
            key: Key name
            default: Default value if key is not found
            
        Returns:
            Value from configuration or default
        """
        if section in self.config and key in self.config[section]:
            return self.config[section][key]
        return default


class MatlabRunner:
    """
    A class for running MATLAB scripts for hydrological modeling and calibration.
    This class encapsulates the functionality for running different MATLAB routines,
    managing the MATLAB engine, and providing a consistent interface for different operations.
    """
    
    def __init__(self, config_manager: Optional[ConfigManager] = None):
        """
        Initialize the MatlabRunner with configuration.
        
        Args:
            config_manager: ConfigManager instance for accessing configuration
                            If None, a new instance will be created
        """
        # Initialize configuration manager
        self.config_manager = config_manager or ConfigManager()
        
        # Get MATLAB paths from configuration
        self.matlab_paths = self.config_manager.get_matlab_paths()
        if not self.matlab_paths:
            # Default MATLAB script paths if none in config
            self.matlab_paths = {
                'main': 'src',
                'functions': 'src/matlab_functions',
                'calibration': 'src/calibration',
                'sensitivity': 'src/sensitivity_analysis',
                'results': 'results'
            }
            
        # Get date settings from configuration
        date_range = self.config_manager.get_date_range()
        self.start_date = date_range.get('start_date', '1979-1-1')
        self.end_date = date_range.get('end_date', '2000-12-31')
        
        # Get calibration settings
        cal_settings = self.config_manager.get_calibration_settings()
        self.objective_function = cal_settings.get('objective_function', 'KGE')
        self.calibration_type = cal_settings.get('type','single_site')
        self.CP = int(cal_settings.get('CP', "1"))
        
        # MATLAB engine instance (will be initialized when needed)
        self._engine = None
    
    def _initialize_engine(self) -> None:
        """Initialize the MATLAB engine and add necessary paths."""
        if self._engine is None:
            self._engine = matlab.engine.start_matlab()
            
            # Add all registered MATLAB paths
            for path in self.matlab_paths.values():
                if os.path.exists(path):
                    self._engine.addpath(path, nargout=0)
    
    def _close_engine(self) -> None:
        """Close the MATLAB engine if it's running."""
        if self._engine is not None:
            self._engine.quit()
            self._engine = None
    
    def _get_execution_params(self) -> Dict[str, Any]:
        """
        Create a dictionary with execution parameters for MATLAB functions.
        
        Returns:
            Dictionary with dateDebut and dateFin parameters.
        """
        execution = {}
        execution['dateDebut'] = self._engine.datenum(self.start_date)
        execution['dateFin'] = self._engine.datenum(self.end_date)
        return execution
    
    def run_simulation(self, 
                      physiographic_path: Optional[str] = None, 
                      params_name: Optional[str] = None, 
                      output_vars: Optional[List[str]] = None, 
                      verbose: Optional[int] = None) -> Any:
        """
        Run the main simulation model.
        
        Args:
            physiographic_path: Path to the physiographic results directory
            params_name: Name of the parameters file (JSON)
            output_vars: List of variable names to output
            verbose: Verbosity level (0 for silent)
            
        Returns:
            MATLAB outputs from the simulation
        """
        try:
            # Get settings from config if not provided
            sim_settings = self.config_manager.get_simulation_settings()
            
            physiographic_path = physiographic_path or sim_settings.get('physiographic_path')
            params_name = params_name or sim_settings.get('params_file')
            output_vars = output_vars or sim_settings.get('output_vars', ['debit'])
            verbose = verbose if verbose is not None else sim_settings.get('verbose', 0)
            
            if not physiographic_path or not params_name:
                raise ValueError("Physiographic path and parameters file must be provided")
            
            self._initialize_engine()
            execution = self._get_execution_params()
            
            # Run the main simulation and return results
            result = self._engine.main_simulation(
                physiographic_path,
                params_name, 
                execution, 
                output_vars, 
                verbose, 
                nargout=1
            )
            return result
        except Exception as e:
            print(f"Simulation error: {e}")
            return None
        finally:
            self._close_engine()
    
    def run_calibration_flow(self, 
                            physiographic_path: Optional[str] = None, 
                            flow_file_path: Optional[str] = None, 
                            params_name: Optional[str] = None, 
                            verbose: Optional[int] = None) -> int:
        """
        Run the flow calibration process.
        
        Args:
            physiographic_path: Path to the physiographic results directory
            flow_file_path: Path to the observed flow file
            params_name: Name of the parameters file (JSON)
            verbose: Verbosity level (0 for silent)
            
        Returns:
            Status code (0 for success)
        """
        try:
            # Get settings from config if not provided
            sim_settings = self.config_manager.get_simulation_settings()
            
            physiographic_path = physiographic_path or sim_settings.get('physiographic_path')
            flow_file_path = flow_file_path or sim_settings.get('flow_file_path')
            params_name = params_name or sim_settings.get('params_file')
            verbose = verbose if verbose is not None else sim_settings.get('verbose', 0)
            thermie = sim_settings.get('thermie', 0)
            
            if not physiographic_path or not flow_file_path or not params_name:
                raise ValueError("Physiographic path, flow file path, and parameters file must be provided")
            
            self._initialize_engine()
            execution = self._get_execution_params()
            
            # Set the prefix name for the calibration results
            prefixName_path = f'results/calibration/CMAES/{self.objective_function}'
            # Check if the folder that will contain the results exists, if not, create it
            if not os.path.exists(prefixName_path):
                os.makedirs(prefixName_path)
            # List of all objective functions to calibrate
            prefixName = f'{prefixName_path}/{self.objective_function}'
            
            # Run the calibration for each objective function
            self._engine.main_calibration_flow(
                physiographic_path, 
                flow_file_path,
                params_name, 
                execution,
                prefixName, 
                self.CP, 
                thermie, 
                nargout=0
            )
            return 0
        except Exception as e:
            print(f"Calibration error: {e}")
            return 1
        finally:
            self._close_engine()
    
    def run_sensitivity_analysis(self, 
                                physiographic_path: Optional[str] = None, 
                                params_name: Optional[str] = None, 
                                parameter_ranges: Optional[Dict[str, List[float]]] = None, 
                                verbose: Optional[int] = None) -> Any:
        """
        Run sensitivity analysis for model parameters.
        
        Args:
            physiographic_path: Path to the physiographic results directory
            params_name: Name of the parameters file (JSON)
            parameter_ranges: Dictionary of parameter names and their ranges for sensitivity analysis
            verbose: Verbosity level (0 for silent)
            
        Returns:
            Results of the sensitivity analysis
        """
        try:
            # Get settings from config if not provided
            sim_settings = self.config_manager.get_simulation_settings()
            
            physiographic_path = physiographic_path or sim_settings.get('physiographic_path')
            params_name = params_name or sim_settings.get('params_file')
            verbose = verbose if verbose is not None else sim_settings.get('verbose', 0)
            thermie = sim_settings.get('thermie', 0)
            
            if not physiographic_path or not params_name:
                raise ValueError("Physiographic path and parameters file must be provided")
            
            if parameter_ranges is None:
                # In the future, could add parameter ranges to config file
                raise ValueError("Parameter ranges must be provided for sensitivity analysis")
            
            self._initialize_engine()
            execution = self._get_execution_params()
            
            # Run sensitivity analysis
            result = self._engine.main_sensitivity(
                physiographic_path,
                params_name,
                execution,
                parameter_ranges,
                verbose,
                nargout=1
            )
            return result
        except Exception as e:
            print(f"Sensitivity analysis error: {e}")
            return None
        finally:
            self._close_engine()

    def add_matlab_path(self, name: str, path: str) -> None:
        """
        Add a new MATLAB scripts path to the runner.
        
        Args:
            name: Identifier for the path
            path: Directory path containing MATLAB scripts
        """
        self.matlab_paths[name] = path
        
        # Update config file
        self.config_manager.update_section('PATHS', {name: path})
        
        # If engine is already running, add the path immediately
        if self._engine is not None and os.path.exists(path):
            self._engine.addpath(path, nargout=0)
    
    def set_date_range(self, start_date: str, end_date: str) -> None:
        """
        Set the date range for simulations.
        
        Args:
            start_date: Start date in format "YYYY-MM-DD"
            end_date: End date in format "YYYY-MM-DD"
        """
        self.start_date = start_date
        self.end_date = end_date
        
        # Update config file
        self.config_manager.update_section('DATES', {
            'start_date': start_date,
            'end_date': end_date
        })
    
    def set_objective_function(self, objective_function: str) -> None:
        """
        Set the objective function for calibration.
        
        Args:
            objective_function: Name of the objective function
        """
        self.objective_function = objective_function
        
        # Update config file
        self.config_manager.update_section('CALIBRATION', {
            'objective_function': objective_function
        })


def main():
    """Example usage of the MatlabRunner class."""
    # Create a config manager and a runner instance
    config_manager = ConfigManager('simulations_setup.txt')
    runner = MatlabRunner(config_manager)
    
    # Get simulation settings from config
    sim_settings = config_manager.get_simulation_settings()
    
    # Example 1: Run flow calibration using config settings
    print("Running flow calibration...")
    runner.set_date_range("1980-1-1", "1990-12-31")
    status = runner.run_calibration_flow()
    print(f"Calibration completed with status: {status}")
    
    # Example 2: Run simulation with specific output variables from config
    # print("\nRunning simulation...")
    # results = runner.run_simulation()
    # print("Simulation completed.")
    
    # Example 3: Using a custom date range - this updates the config file
    # print("\nUpdating date range in configuration...")
    # runner.set_date_range("1990-1-1", "1995-12-31")
    
    # print("\nRunning simulation with updated date range...")
    # results = runner.run_simulation()
    # print("Custom simulation completed.")


if __name__ == "__main__":
    main()
