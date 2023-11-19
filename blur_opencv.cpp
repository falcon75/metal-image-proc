#include <iostream>
#include <opencv2/opencv.hpp>

int main() {
    // Load input image
    cv::Mat inputImage = cv::imread("input.jpg");

    if (inputImage.empty()) {
        std::cerr << "Error: Unable to load input image." << std::endl;
        return 1;
    }

    // Record start time
    auto startTime = std::chrono::high_resolution_clock::now();
    
    // Apply blur
    cv::GaussianBlur(inputImage, inputImage, cv::Size(21, 21), 0);

    // Record time after blur
    auto blurTime = std::chrono::high_resolution_clock::now();
    auto blurDuration = std::chrono::duration_cast<std::chrono::milliseconds>(blurTime - startTime).count();

    // Save output image
    cv::imwrite("output/output_opencv.jpg", inputImage);

    // Record time after image writing
    auto endTime = std::chrono::high_resolution_clock::now();
    auto writeTime = std::chrono::duration_cast<std::chrono::milliseconds>(endTime - blurTime).count();

    // Print timings
    std::cout << "Blur Time: " << blurDuration << " ms\n";
    std::cout << "Write Time: " << writeTime << " ms\n";

    return 0;
}
