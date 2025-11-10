# Nothing special here, just specifying how to print test parameters
# as part of the test name.
def pytest_make_parametrize_id(config, val, argname):
    return f"{argname}={val}"
