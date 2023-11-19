#include <iostream>
#include <opencv2/opencv.hpp>

int main() {

    auto startTime = std::chrono::high_resolution_clock::now();
    // Load input image
    cv::Mat inputImage = cv::imread("input.jpg");

    if (inputImage.empty()) {
        std::cerr << "Error: Unable to load input image." << std::endl;
        return 1;
    }

    // Record start time
    auto blurStartTime = std::chrono::high_resolution_clock::now();
    auto loadDuration = std::chrono::duration_cast<std::chrono::milliseconds>(blurStartTime - startTime).count();
    
    // Apply blur
    cv::Mat kernel = cv::Mat::ones(19, 19, CV_32F) / 361;
    cv::filter2D(inputImage, inputImage, -1, kernel);

    // Record time after blur
    auto blurTime = std::chrono::high_resolution_clock::now();
    auto blurDuration = std::chrono::duration_cast<std::chrono::milliseconds>(blurTime - startTime).count();

    // Save output image
    cv::imwrite("output/opencv.jpg", inputImage);

    // Record time after image writing
    auto endTime = std::chrono::high_resolution_clock::now();
    auto writeTime = std::chrono::duration_cast<std::chrono::milliseconds>(endTime - blurTime).count();

    // Print timings
    std::cout << "Write Time: " << loadDuration << " ms | ";
    std::cout << "Blur Time: " << blurDuration << " ms | ";
    std::cout << "Write Time: " << writeTime << " ms \n";

    return 0;
}
