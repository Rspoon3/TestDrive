//
//  InstancedSnowRenderer.swift
//  TestDrive
//

import MetalKit
import QuartzCore

/// Draws the snow with one instanced Metal draw call per frame.
///
/// The flake list is uploaded to the GPU once. Every frame the renderer only sends the elapsed time, and the vertex
/// shader (`snowVertex`) works out each flake's position from it, the same closed-form way the Canvas snow does.
@MainActor
final class InstancedSnowRenderer: NSObject, MTKViewDelegate {
    private let commandQueue: any MTLCommandQueue
    private let pipelineState: any MTLRenderPipelineState
    private let device: any MTLDevice
    private let startTime = CACurrentMediaTime()

    private var configuration: SnowfallConfiguration
    private var instanceBuffer: (any MTLBuffer)?
    private var instanceCount = 0

    // MARK: - Initializer

    /// Creates a renderer for a view, or `nil` if Metal isn't available.
    /// - Parameters:
    ///   - view: The view to draw into. Its device, pixel format and transparency are used and set up.
    ///   - configuration: How much snow falls, how fast, and how windy it is.
    init?(view: MTKView, configuration: SnowfallConfiguration) {
        guard
            let device = view.device,
            let commandQueue = device.makeCommandQueue(),
            let library = device.makeDefaultLibrary(),
            let vertexFunction = library.makeFunction(name: "snowVertex"),
            let fragmentFunction = library.makeFunction(name: "snowFragment")
        else { return nil }

        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = vertexFunction
        descriptor.fragmentFunction = fragmentFunction
        descriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat

        // The fragment shader returns premultiplied white, so blend with "one, one minus source alpha".
        let attachment = descriptor.colorAttachments[0]
        attachment?.isBlendingEnabled = true
        attachment?.rgbBlendOperation = .add
        attachment?.alphaBlendOperation = .add
        attachment?.sourceRGBBlendFactor = .one
        attachment?.sourceAlphaBlendFactor = .one
        attachment?.destinationRGBBlendFactor = .oneMinusSourceAlpha
        attachment?.destinationAlphaBlendFactor = .oneMinusSourceAlpha

        guard let pipelineState = try? device.makeRenderPipelineState(descriptor: descriptor) else { return nil }

        self.device = device
        self.commandQueue = commandQueue
        self.pipelineState = pipelineState
        self.configuration = configuration
        super.init()

        uploadInstances()
    }

    // MARK: - Public Helpers

    /// Replaces the flakes when the snowfall parameters change.
    /// - Parameter configuration: The new snowfall parameters.
    func update(configuration: SnowfallConfiguration) {
        guard configuration != self.configuration else { return }

        self.configuration = configuration
        uploadInstances()
    }

    // MARK: - MTKViewDelegate

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

    func draw(in view: MTKView) {
        guard
            let instanceBuffer,
            instanceCount > 0,
            let descriptor = view.currentRenderPassDescriptor,
            let drawable = view.currentDrawable,
            let commandBuffer = commandQueue.makeCommandBuffer(),
            let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor)
        else { return }

        var uniforms = SnowUniforms(
            viewSize: SIMD2(Float(view.bounds.width), Float(view.bounds.height)),
            time: Float(CACurrentMediaTime() - startTime),
            windStrength: Float(configuration.windStrength),
            windDrift: Float(configuration.windDrift)
        )

        encoder.setRenderPipelineState(pipelineState)
        encoder.setVertexBuffer(instanceBuffer, offset: 0, index: 0)
        encoder.setVertexBytes(&uniforms, length: MemoryLayout<SnowUniforms>.stride, index: 1)
        encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4, instanceCount: instanceCount)
        encoder.endEncoding()

        commandBuffer.present(drawable)
        commandBuffer.commit()
    }

    // MARK: - Private Helpers

    /// Builds the flakes for the current configuration and copies them into a GPU buffer.
    private func uploadInstances() {
        let instances = SnowInstance.makeInstances(for: configuration)
        instanceCount = instances.count

        instanceBuffer = instances.withUnsafeBytes { bytes in
            guard let baseAddress = bytes.baseAddress else { return nil }
            return device.makeBuffer(bytes: baseAddress, length: bytes.count, options: .storageModeShared)
        }
    }
}
