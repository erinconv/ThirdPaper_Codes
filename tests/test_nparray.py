import numpy as np
import matlab.engine
import unittest

class TestNumpyArray(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        """Set up MATLAB engine once for all tests."""
        cls.eng = matlab.engine.start_matlab()

    @classmethod
    def tearDownClass(cls):
        """Clean up MATLAB engine after all tests."""
        cls.eng.quit()

    def create_matlab_array(self, matlab_command):
        """
        Helper method to create a MATLAB array and convert it to NumPy.
        
        Args:
            matlab_command (str): MATLAB command to create the array
            
        Returns:
            np.ndarray: NumPy array converted from MATLAB array
        """
        matlab_array = self.eng.eval(matlab_command, nargout=1)
        return np.array(matlab_array)

    def test_basic_array_conversion(self):
        """Test basic 3x3 array conversion from MATLAB to NumPy."""
        numpy_array = self.create_matlab_array('[1, 2, 3; 4, 5, 6; 7, 8, 9]')
        
        # Test array type
        self.assertIsInstance(numpy_array, np.ndarray, 
                            "Output should be a NumPy array")
        
        # Test array shape
        self.assertEqual(numpy_array.shape, (3, 3), 
                        "Array shape should be (3, 3)")
        
        # Test array contents
        expected_array = np.array([[1, 2, 3], [4, 5, 6], [7, 8, 9]])
        np.testing.assert_array_equal(numpy_array, expected_array,
                                    "Array contents do not match expected values")
        
        # Test array data type
        self.assertEqual(numpy_array.dtype, np.float64,
                        "Array should have float64 data type")

    def test_empty_array(self):
        """Test conversion of empty MATLAB array."""
        numpy_array = self.create_matlab_array('[]')
        self.assertEqual(numpy_array.size, 0,
                        "Empty array should have size 0")

    def test_single_element_array(self):
        """Test conversion of single-element MATLAB array."""
        numpy_array = self.create_matlab_array('42')
        self.assertEqual(numpy_array.item(), 42,
                        "Single element array should contain correct value")

    def test_complex_numbers(self):
        """Test conversion of complex numbers."""
        numpy_array = self.create_matlab_array('1 + 2i')
        self.assertEqual(numpy_array.item(), 1 + 2j,
                        "Complex number conversion failed")

    def test_different_dimensions(self):
        """Test arrays with different dimensions."""
        # Test 1D array
        array_1d = self.create_matlab_array('[1 2 3 4 5]')
        self.assertEqual(array_1d.shape, (1, 5),
                        "1D array shape incorrect")

        # Test 2D array with different rows and columns
        array_2d = self.create_matlab_array('[1 2; 3 4; 5 6]')
        self.assertEqual(array_2d.shape, (3, 2),
                        "2D array shape incorrect")

    def test_array_operations(self):
        """Test that converted arrays work correctly with NumPy operations."""
        numpy_array = self.create_matlab_array('[1, 2; 3, 4]')
        
        # Test sum
        self.assertEqual(np.sum(numpy_array), 10,
                        "Sum operation failed")
        
        # Test mean
        self.assertEqual(np.mean(numpy_array), 2.5,
                        "Mean operation failed")
        
        # Test matrix multiplication
        result = np.matmul(numpy_array, numpy_array)
        expected = np.array([[7, 10], [15, 22]])
        np.testing.assert_array_almost_equal(result, expected,
                                           err_msg="Matrix multiplication failed")

if __name__ == '__main__':
    unittest.main()
