import matlab.engine

def test_matlab_package():
    try:
        # Start the MATLAB engine
        eng = matlab.engine.start_matlab()
        
        # Run a simple MATLAB command
        result = eng.eval('2 + 2')
        
        # Print the result
        print(f'Test Result: 2 + 2 = {result}')
        print(matlab.__file__)
    except Exception as e:
        print(f'An error occurred: {e}')
    finally:
        # Ensure the MATLAB engine is stopped
        if 'eng' in locals():
            eng.quit()

# Call the test function
test_matlab_package()
