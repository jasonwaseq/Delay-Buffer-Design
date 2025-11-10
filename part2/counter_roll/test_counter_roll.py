import git
import os
import sys
import git

# I don't like this, but it's convenient.
_REPO_ROOT = git.Repo(search_parent_directories=True).working_tree_dir
assert (os.path.exists(_REPO_ROOT)), "REPO_ROOT path must exist"
sys.path.append(os.path.join(_REPO_ROOT, "util"))
from utilities import runner, lint, assert_resolvable, clock_start_sequence, reset_sequence
tbpath = os.path.dirname(os.path.realpath(__file__))

import pytest

import cocotb

from cocotb.clock import Clock
from cocotb.regression import TestFactory
from cocotb.utils import get_sim_time
from cocotb.triggers import Timer, ClockCycles, RisingEdge, FallingEdge, with_timeout
from cocotb.types import LogicArray, Range

from cocotb_test.simulator import run

from cocotbext.axi import AxiLiteBus, AxiLiteMaster, AxiStreamSink, AxiStreamMonitor, AxiStreamBus

from pytest_utils.decorators import max_score, visibility, tags
   
import random
random.seed(42)

timescale = "1ps/1ps"

timescale = "1ps/1ps"
tests = ['reset_test',
         'single_cycle_test_001',
         'single_cycle_test_002',
         'single_cycle_test_003',
         'single_cycle_test_004',
         'limit_test_001',
         'limit_test_002',
         'fuzz_test_001',
         'fuzz_test_002',
         'fuzz_test_003'
         ]

@pytest.mark.parametrize("reset_val_p,max_val_p", [(1, 3), (11, 67), (30, 31), (0, 11)])
@pytest.mark.parametrize("test_name", tests)
@pytest.mark.parametrize("simulator", ["verilator", "icarus"])
@max_score(0)
def test_each(test_name, simulator, reset_val_p, max_val_p):
    # This line must be first
    parameters = dict(locals())
    del parameters['test_name']
    del parameters['simulator']
    runner(simulator, timescale, tbpath, parameters, testname=test_name)

@pytest.mark.parametrize("reset_val_p,max_val_p", [(1, 3), (11, 67), (30, 31), (0, 11)])
@pytest.mark.parametrize("simulator", ["verilator", "icarus"])
@max_score(1)
def test_all(simulator, reset_val_p, max_val_p):
    # This line must be first
    parameters = dict(locals())
    del parameters['simulator']
    runner(simulator, timescale, tbpath, parameters)

@pytest.mark.parametrize("reset_val_p, max_val_p", [(11, 67)])
@pytest.mark.parametrize("simulator", ["verilator"])
@max_score(.4)
def test_lint(simulator, reset_val_p, max_val_p):
    # This line must be first
    parameters = dict(locals())
    del parameters['simulator']
    lint(simulator, timescale, tbpath, parameters)

@pytest.mark.parametrize("reset_val_p, max_val_p", [(11, 67)])
@pytest.mark.parametrize("simulator", ["verilator"])
@max_score(.1)
def test_style(simulator, reset_val_p, max_val_p):
    # This line must be first
    parameters = dict(locals())
    del parameters['simulator']
    lint(simulator, timescale, tbpath, parameters, compile_args=["--lint-only", "-Wwarn-style", "-Wno-lint"])

class CounterModel():
    def __init__(self, width_p, reset_val_p, max_val_p,
                 clk_i, reset_i, up_i, down_i, count_o):
        self._width_p = width_p.value
        self._reset_val_p = reset_val_p.value
        self._max_val_p = max_val_p.value
        self._clk_i = clk_i
        self._reset_i = reset_i
        self._up_i = up_i
        self._down_i = down_i
        self._count_o = count_o
        self._coro_run = None
        self._count = 0

    def start(self):
        """Start model"""
        if self._coro_run is not None:
            raise RuntimeError("Model already started")
        self._coro_run = cocotb.start_soon(self._run())

    async def _run(self):
        while True:
            await RisingEdge(self._clk_i)
            if(not(self._reset_i.value.is_resolvable)):
                pass
            elif(self._reset_i.value == 1):
                self._count = self._reset_val_p
            elif(not(self._up_i.value.is_resolvable and self._down_i.value.is_resolvable)):
                pass
            elif(self._up_i.value and self._down_i.value):
                pass # Do nothing
            elif(self._up_i.value and not self._down_i.value and (self._count != self._max_val_p)):
                self._count += 1
            elif(self._up_i.value and not self._down_i.value):
                self._count = 0
            elif(not self._up_i.value and self._down_i.value and (self._count != 0)):
                self._count -= 1
            elif(not self._up_i.value and self._down_i.value):
                self._count = self._max_val_p
      
    def stop(self) -> None:
        """Stop monitor"""
        if self._coro_run is None:
            raise RuntimeError("Monitor never started")
         
    
@cocotb.test()
async def reset_test(dut):
    """Test for Initialization"""

    clk_i = dut.clk_i
    reset_i = dut.reset_i
    up_i = dut.up_i
    down_i = dut.down_i
    count_o = dut.count_o

    up_i.value = LogicArray(['x'])
    down_i.value = LogicArray(['x'])

    await clock_start_sequence(clk_i)
    model = CounterModel(dut.width_p, dut.reset_val_p, dut.max_val_p, dut.clk_i, dut.reset_i, dut.up_i, dut.down_i, dut.count_o)
    model.start()
    await reset_sequence(clk_i, reset_i, 10)

    # Set the initial inputs
    up_i.value = 0
    down_i.value = 0

    await FallingEdge(dut.clk_i)

    assert count_o.value.is_resolvable, f"Unresolvable value (x or z in some or all bits) at Time {get_sim_time(units='ns')}ns."
    assert count_o.value == model._count , f"Incorrect Result: count_o != {model._count}. Got: {count_o.value} at Time {get_sim_time(units='ns')}ns."

async def single_cycle_test(dut, up, down):
    """Single-cycle test for basic (up/down) functionality"""

    clk_i = dut.clk_i
    reset_i = dut.reset_i
    up_i = dut.up_i
    down_i = dut.down_i
    count_o = dut.count_o

    up_i.value = LogicArray(['x'])
    down_i.value = LogicArray(['x'])

    await clock_start_sequence(clk_i)
    model = CounterModel(dut.width_p, dut.reset_val_p, dut.max_val_p, dut.clk_i, dut.reset_i, dut.up_i, dut.down_i, dut.count_o)
    model.start()
    await reset_sequence(clk_i, reset_i, 10)

    # Set the initial inputs
    up_i.value = 0
    down_i.value = 0

    # Increment once.
    await FallingEdge(dut.clk_i)
    up_i.value = up
    down_i.value = down
    
    await FallingEdge(dut.clk_i)

    # Check after one cycle of up
    assert count_o.value.is_resolvable, f"Unresolvable value (x or z in some or all bits) at Time {get_sim_time(units='ns')}ns."
    assert count_o.value == model._count , f"Incorrect Result: count_o != {model._count}. Got: {count_o.value} at Time {get_sim_time(units='ns')}ns."

    # Value should remain constant.
    up_i.value = up
    down_i.value = down

    await FallingEdge(dut.clk_i)

    assert count_o.value.is_resolvable, f"Unresolvable value (x or z in some or all bits) at Time {get_sim_time(units='ns')}ns."
    assert count_o.value == model._count , f"Incorrect Result: count_o != {model._count}. Got: {count_o.value} at Time {get_sim_time(units='ns')}ns."

tf = TestFactory(test_function=single_cycle_test)
tf.add_option(name='up', optionlist=[0,1])
tf.add_option(name='down', optionlist=[0,1])
tf.generate_tests()

async def wait_for(dut, value):
    while(dut.count_o.value.is_resolvable and dut.count_o.value != value):
        await FallingEdge(dut.clk_i)

async def limit_test(dut, up, down):
    """Test for max_val_p/0 limits."""

    clk_i = dut.clk_i
    reset_i = dut.reset_i
    up_i = dut.up_i
    down_i = dut.down_i
    count_o = dut.count_o

    up_i.value = LogicArray(['x'])
    down_i.value = LogicArray(['x'])

    await clock_start_sequence(clk_i)
    model = CounterModel(dut.width_p, dut.reset_val_p, dut.max_val_p, dut.clk_i, dut.reset_i, dut.up_i, dut.down_i, dut.count_o)
    model.start()
    await reset_sequence(clk_i, reset_i, 10)

    # Set the initial inputs
    up_i.value = 0
    down_i.value = 0
    
    await FallingEdge(dut.clk_i)
    up_i.value = up
    down_i.value = down

    if(up):
        value = dut.max_val_p.value
        timeout = dut.max_val_p.value - dut.reset_val_p.value + 1

    elif(down):
        value = 0
        timeout = 2*dut.reset_val_p.value + 1
    
    await with_timeout(wait_for(dut, value=value), timeout, 'ns')

    # Increment once more.
    await FallingEdge(dut.clk_i)

    assert count_o.value.is_resolvable, f"Unresolvable value (x or z in some or all bits) at Time {get_sim_time(units='ns')}ns."
    assert count_o.value == model._count_o , f"Incorrect Result: count_o != {model._count_o}. Got: {count_o.value} at Time {get_sim_time(units='ns')}ns."

tf = TestFactory(test_function=limit_test)
tf.add_option(('up', 'down'), [(1, 0), (0, 1)])
tf.generate_tests()

async def fuzz_test(dut, l):
    """Test for Random Input"""

    clk_i = dut.clk_i
    reset_i = dut.reset_i
    up_i = dut.up_i
    down_i = dut.down_i
    count_o = dut.count_o

    up_i.value = LogicArray(['x'])
    down_i.value = LogicArray(['x'])

    await clock_start_sequence(clk_i)
    model = CounterModel(dut.width_p, dut.reset_val_p, dut.max_val_p, dut.clk_i, dut.reset_i, dut.up_i, dut.down_i, dut.count_o)
    model.start()
    await reset_sequence(clk_i, reset_i, 10)

    # Set the initial inputs
    up_i.value = 0
    down_i.value = 0

    await FallingEdge(dut.clk_i)

    seq = [random.randint(0, 4) for i in range(l)]
    for i in seq:
        await FallingEdge(dut.clk_i)
        up_i.value = (i == 1 or i == 3)
        down_i.value = (i == 2 or i == 3)
        assert count_o.value.is_resolvable, f"Unresolvable value (x or z in some or all bits) at Time {get_sim_time(units='ns')}ns."
        assert count_o.value == model._count_o , f"Incorrect Result: count_o != {model._count_o}. Got: {count_o.value} at Time {get_sim_time(units='ns')}ns."
    

tf = TestFactory(test_function=fuzz_test)
tf.add_option(name='l', optionlist=[10, 100, 1000])
tf.generate_tests()
