import Cocoa
import MetalKit

class MetalImageBlur {
    let device: MTLDevice
    let commandQueue: MTLCommandQueue
    let pipelineState: MTLComputePipelineState

    init(device: MTLDevice) {
        self.device = device
        self.commandQueue = device.makeCommandQueue()!

        // Load the Metal shader code for image blur
        let shaderSource = """
        #include <metal_stdlib>
        using namespace metal;

        kernel void blurImage(
            texture2d<float, access::read> input [[texture(0)]],
            texture2d<float, access::write> output [[texture(1)]],
            uint2 gid [[thread_position_in_grid]]
        ) {
            // Image dimensions
            int width = input.get_width();
            int height = input.get_height();

            // Blur radius
            int blurRadius = 9 ;

            // Accumulator for blurred color
            float4 blurSum = float4(0.0);

            // Count of pixels in the average
            int count = 0;

            // Iterate over neighboring pixels within the blur radius
            for (int dy = -blurRadius; dy <= blurRadius; ++dy) {
                for (int dx = -blurRadius; dx <= blurRadius; ++dx) {
                    int nx = int(gid.x) + dx;
                    int ny = int(gid.y) + dy;

                    // Check bounds
                    if (nx >= 0 && nx < width && ny >= 0 && ny < height) {
                        blurSum += input.read(uint2(nx, ny));
                        count++;
                    }
                }
            }

            // Compute average and write to output texture
            output.write(blurSum / float4(count), gid);
        }
        """

        // Compile the shader code
        let library = try! device.makeLibrary(source: shaderSource, options: nil)
        let kernelFunction = library.makeFunction(name: "blurImage")!
        self.pipelineState = try! device.makeComputePipelineState(function: kernelFunction)
    }

    func blurImage(inputTexture: MTLTexture, outputTexture: MTLTexture) {
        let commandBuffer = commandQueue.makeCommandBuffer()!
        let computeEncoder = commandBuffer.makeComputeCommandEncoder()!

        computeEncoder.setComputePipelineState(pipelineState)
        computeEncoder.setTexture(inputTexture, index: 0)
        computeEncoder.setTexture(outputTexture, index: 1)

        // Calculate threadgroup and grid size based on the output texture size
        let threadGroupSize = MTLSize(width: 16, height: 16, depth: 1)
        let threadGroups = MTLSize(
            width: (outputTexture.width + threadGroupSize.width - 1) / threadGroupSize.width,
            height: (outputTexture.height + threadGroupSize.height - 1) / threadGroupSize.height,
            depth: 1
        )

        computeEncoder.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadGroupSize)
        computeEncoder.endEncoding()

        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
    }
}

let t1 = Date()
// Create a Metal device
let device = MTLCreateSystemDefaultDevice()!
// Initialize MetalImageBlur
let metalImageBlur = MetalImageBlur(device: device)

let t2 = Date()
// Load input image from file
let inputImagePath = "input.jpg"
guard let inputImage = NSImage(contentsOfFile: inputImagePath) else {
    fatalError("Failed to load input image.")
}
// Create Metal textures for input and output images
let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
    pixelFormat: .rgba8Unorm,
    width: Int(inputImage.size.width),
    height: Int(inputImage.size.height),
    mipmapped: false
)
// Make sure to include .shaderWrite in the usage
textureDescriptor.usage = [.shaderRead, .shaderWrite]

let inputTexture = device.makeTexture(descriptor: textureDescriptor)!
let outputTexture = device.makeTexture(descriptor: textureDescriptor)!

// Convert input image to Metal texture
guard let inputImageRef = inputImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
    fatalError("Failed to convert input image to Metal texture.")
}

let inputBytesPerRow = inputImageRef.bytesPerRow
let inputBytes = UnsafeMutableRawPointer.allocate(byteCount: inputBytesPerRow * inputImageRef.height, alignment: 1)
defer { inputBytes.deallocate() }

let inputBitmapInfo = inputImageRef.bitmapInfo
let inputContext = CGContext(
    data: inputBytes,
    width: inputImageRef.width,
    height: inputImageRef.height,
    bitsPerComponent: 8,
    bytesPerRow: inputBytesPerRow,
    space: inputImageRef.colorSpace ?? CGColorSpaceCreateDeviceRGB(),
    bitmapInfo: inputBitmapInfo.rawValue
)

inputContext?.draw(inputImageRef, in: CGRect(x: 0, y: 0, width: inputImageRef.width, height: inputImageRef.height))
inputTexture.replace(region: MTLRegion(
    origin: MTLOrigin(x: 0, y: 0, z: 0),
    size: MTLSize(width: inputTexture.width, height: inputTexture.height, depth: 1)
), mipmapLevel: 0, withBytes: inputBytes, bytesPerRow: inputBytesPerRow)

let t3 = Date()
// Apply blur
metalImageBlur.blurImage(inputTexture: inputTexture, outputTexture: outputTexture)


let t4 = Date()
// Save output image to file
let outputImagePath = "output/output_metal.jpg"

let outputBitmap = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: outputTexture.width,
    pixelsHigh: outputTexture.height,
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .calibratedRGB,
    bytesPerRow: outputTexture.width * 4,
    bitsPerPixel: 32
)!

outputTexture.getBytes(
    outputBitmap.bitmapData!,
    bytesPerRow: outputTexture.width * 4,
    from: MTLRegion(
        origin: MTLOrigin(x: 0, y: 0, z: 0),
        size: MTLSize(width: outputTexture.width, height: outputTexture.height, depth: 1)
    ),
    mipmapLevel: 0
)

let outputImageData = outputBitmap.representation(using: .jpeg, properties: [:])
try! outputImageData?.write(to: URL(fileURLWithPath: outputImagePath))
let t5 = Date()

print("Metal Init: \(String(format: "%.4f", t2.timeIntervalSince(t1)))s | Image Load: \(String(format: "%.4f", t3.timeIntervalSince(t2)))s | Blur Call: \(String(format: "%.4f", t4.timeIntervalSince(t3)))s | Image Write: \(String(format: "%.4f", t5.timeIntervalSince(t4)))s")

