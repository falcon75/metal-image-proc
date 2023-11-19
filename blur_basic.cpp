#include <iostream>
#include <opencv2/opencv.hpp>


// Function to apply a box blur to an image
void applyBoxBlur(cv::Mat& inputImage, int blurRadius) {
    cv::Mat blurredImage = inputImage.clone();

    // Iterate over each pixel in the image
    for (int y = 0; y < inputImage.rows; ++y) {
        for (int x = 0; x < inputImage.cols; ++x) {
            cv::Vec3f sum(0, 0, 0);  // Use floating-point type for sum
            int count = 0;

            // Iterate over neighboring pixels within the blur radius
            for (int dy = -blurRadius; dy <= blurRadius; ++dy) {
                for (int dx = -blurRadius; dx <= blurRadius; ++dx) {
                    int nx = x + dx;
                    int ny = y + dy;

                    // Check bounds
                    if (nx >= 0 && nx < inputImage.cols && ny >= 0 && ny < inputImage.rows) {
                        sum += inputImage.at<cv::Vec3b>(ny, nx);
                        ++count;
                    }
                }
            }

            // Compute average and update the blurred image
            blurredImage.at<cv::Vec3b>(y, x) = cv::Vec3b(sum[0] / count, sum[1] / count, sum[2] / count);
        }
    }

    // Convert the blurred image to 8-bit unsigned integer type
    blurredImage.convertTo(blurredImage, CV_8UC3);

    // Update the input image with the blurred result
    inputImage = blurredImage;
}




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
    applyBoxBlur(inputImage, 9);

    // Record time after blur
    auto blurTime = std::chrono::high_resolution_clock::now();
    auto blurDuration = std::chrono::duration_cast<std::chrono::milliseconds>(blurTime - startTime).count();

    // Save output image
    cv::imwrite("output/basic.jpg", inputImage);

    // Record time after image writing
    auto endTime = std::chrono::high_resolution_clock::now();
    auto writeTime = std::chrono::duration_cast<std::chrono::milliseconds>(endTime - blurTime).count();

    // Print timings
    std::cout << "Blur Time: " << blurDuration << " ms\n";
    std::cout << "Write Time: " << writeTime << " ms\n";

    return 0;
}
