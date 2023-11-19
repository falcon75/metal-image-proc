# g++ flags
CFLAGS = -Wall -Wextra -std=c++11
INCLUDE_FLAGS = -I /opt/homebrew/Cellar/opencv/4.8.1_4/include/opencv4 
OPENCV_FLAGS = -lopencv_core -lopencv_imgproc -lopencv_highgui -lopencv_imgcodecs

# Output file
OUT = blur_program

# Build target
opencv:
	mkdir -p build
	g++ $(CFLAGS) -o build/blur_opencv blur_opencv.cpp $(INCLUDE_FLAGS) $(OPENCV_FLAGS)

metal:
	mkdir -p build
	swiftc -o build/blur_metal blur_metal.swift

all:
	make opencv
	make metal

clean:
	rm -f build/*
