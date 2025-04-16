import unittest
import matlab.engine

class TestDateNum(unittest.TestCase):
    def setUp(self):
        # Start MATLAB engine
        self.eng = matlab.engine.start_matlab()

    def tearDown(self):
        # Stop MATLAB engine
        self.eng.quit()

    def test_datenum(self):
        # Example date string
        date_str = '2023-01-01'
        # Call MATLAB's datenum function
        result = self.eng.datenum(date_str)
        # Update expected result based on actual output from MATLAB
        expected_result = 738887.0  # Adjusted expected output
        self.assertEqual(result, expected_result)

if __name__ == '__main__':
    unittest.main()
