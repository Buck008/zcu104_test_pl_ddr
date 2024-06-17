# Compiler
CXX := g++

# Compiler flags
CXXFLAGS :=  -O3

# Source files
SRCS := main.cpp FPGA_DDR.cpp FPGA_init.cpp FPGA_basic.cpp

# Target executable
TARGET := main

# Default target
main: $(SRCS)
	$(CXX) $(CXXFLAGS) -o $(TARGET) $^

# Clean up build files
clean:
	rm -f $(TARGET)

# Phony targets
.PHONY: main clean
