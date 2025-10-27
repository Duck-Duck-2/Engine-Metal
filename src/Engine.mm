//
//  Engine.mm
//  Engine Metal
//
//  Created by Max Shi on 10/20/25.
//

#include "Engine.hpp"
#include <chrono>

Engine::Engine() {
    initDevice();
    initWindow();
    
    createTriangle();
    createDefaultLibrary();
    createCommandQueue();
    createRenderPipeline();
}

void Engine::run() {
    while (!glfwWindowShouldClose(glfwWindow)) {
        auto start = std::chrono::high_resolution_clock::now();
        // @autoreleasepool is an Objective-C feature that tells the compiler to automatically manage the memory
        // since this is an Objective-C feature, this only works on the Objective-C (Metal) objects
        @autoreleasepool {
            // waits until a drawable is available, then returns it
            // by default, there can only be 3 drawables at a time
            // drawables may be unavailable if the CPU thread is running faster than the GPU
            // or if the window compositor decides to defer the render buffer swap
            metalDrawable = (__bridge CA::MetalDrawable*)[metalLayer nextDrawable];
            draw();
        }
        glfwPollEvents();
        std::cout << std::chrono::duration_cast<std::chrono::milliseconds>(std::chrono::high_resolution_clock::now() - start) << std::endl;
    }
}

void Engine::cleanup() {
    glfwTerminate();
    metalDevice->release();
    triangleVertexBuffer->release();
}

void Engine::initDevice() {
    // the device gives access to the GPU
    metalDevice = MTL::CreateSystemDefaultDevice();
}

void Engine::initWindow() {
    glfwInit();
    // sets the hint (setting) of the client api to no api, telling GLFW to not create an OpenGL context
    glfwWindowHint(GLFW_CLIENT_API, GLFW_NO_API);
    glfwWindow = glfwCreateWindow(1280, 720, "Metal Engine", NULL, NULL);
    if (!glfwWindow) {
        glfwTerminate();
        exit(EXIT_FAILURE);
    }

    // gets the underlying native cocoa window
    metalWindow = glfwGetCocoaWindow(glfwWindow);
    // a view is a section of the window that is a container for rendering components, other views, etc.
    // creates the metal layer, which is the rendering component of the view
    // [] means to send a message to a receiver [Receiver Message]
    // in this case, the receiver is a class and the message is a class method
    // this tells the class to run that class method
    metalLayer = [CAMetalLayer layer];
    // tells the metal layer which device to use
    // (__bridge id<type>) is an Objective-C tyecast to <type> without changing ownership
    metalLayer.device = (__bridge id<MTLDevice>)metalDevice;
    // turns off VSYNC
    // even though it's direct-to-display doesn't appear to be completely unthrottled, especially in windowed mode
    // and has lag spikes
    metalLayer.displaySyncEnabled = NO;
    // specifies the color buffer format (BGRA, 8 bit, unsigned, normalized)
    metalLayer.pixelFormat = MTLPixelFormatBGRA8Unorm;
    // the content view is the view that encompasses the entire window
    metalWindow.contentView.layer = metalLayer;
    // specifies that the layer will be used for rendering
    // the layer is necessary for GPU/Metal rendering
    // the default is basic CPU rendering on a built-in CPU-rendering surface (legacy feature from from when rendering was CPU-based)
    metalWindow.contentView.wantsLayer = YES;
}

void Engine::createTriangle() {
    simd::float3 triangleVertices[] = {
        {-0.5f, -0.5f, 0.0f},
        { 0.5f, -0.5f, 0.0f},
        { 0.0f,  0.5f, 0.0f}
    };

    // metalDevice->newBuffer(pointer to array, size of array, resource mode)
    triangleVertexBuffer = metalDevice->newBuffer(&triangleVertices, sizeof(triangleVertices), MTL::ResourceStorageModeShared);
}

void Engine::createDefaultLibrary() {
    // Xcode precompiles shaders at build time
    // the default library contains these compiled shaders
    // it's more like accessing the default library than making it
    metalDefaultLibrary = metalDevice->newDefaultLibrary();
    if(!metalDefaultLibrary){
        std::cerr << "Failed to load default library.";
        std::exit(-1);
    }
}

void Engine::createCommandQueue() {
    // holds command buffers
    metalCommandQueue = metalDevice->newCommandQueue();
}

void Engine::createRenderPipeline() {
    // creates an instance that represents a shader function
    // newFunction(NSString of function name)
    // NSString is the string type Metal uses
    // NS::String::string(const char*, encoder) type casts a const char* of a certain encoder to an NSString
    MTL::Function* vertexShader = metalDefaultLibrary->newFunction(NS::String::string("vertexShader", NS::ASCIIStringEncoding));
    // checks if the shader exists
    assert(vertexShader);
    MTL::Function* fragmentShader = metalDefaultLibrary->newFunction(NS::String::string("fragmentShader", NS::ASCIIStringEncoding));
    assert(fragmentShader);

    // creates the render pipeline descriptor, which handles the config of the render pipeline
    // allocates the memory and then initializes it
    MTL::RenderPipelineDescriptor* renderPipelineDescriptor = MTL::RenderPipelineDescriptor::alloc()->init();
    renderPipelineDescriptor->setVertexFunction(vertexShader);
    renderPipelineDescriptor->setFragmentFunction(fragmentShader);
    assert(renderPipelineDescriptor);
    MTL::PixelFormat pixelFormat = (MTL::PixelFormat)metalLayer.pixelFormat;
    // configures the color format and operations
    renderPipelineDescriptor->colorAttachments()->object(0)->setPixelFormat(pixelFormat);

    NS::Error* error;
    // given the descriptor, which holds the config, creates the render pipeline state, which is the instance that actually represents a "state" or setting of the render pipeline that can be run
    // essentially, it represents the compiled, executable rendering pipeline
    metalRenderPipelineState = metalDevice->newRenderPipelineState(renderPipelineDescriptor, &error);
    if (error) {
        std::cerr << error->localizedDescription() << std::endl;
        error->release();
    }
    
    vertexShader->release();
    fragmentShader->release();
    renderPipelineDescriptor->release();
}

void Engine::draw() {
    sendRenderCommand();
}

void Engine::sendRenderCommand() {
    // adds command buffer to command queue
    // holds GPU commands
    metalCommandBuffer = metalCommandQueue->commandBuffer();

    // manages configuration of render pass, which is when a collection of rendering commands pass through the rendering pipeline together
    MTL::RenderPassDescriptor* renderPassDescriptor = MTL::RenderPassDescriptor::alloc()->init();
    // gets the color attachment
    MTL::RenderPassColorAttachmentDescriptor* cd = renderPassDescriptor->colorAttachments()->object(0);
    cd->setTexture(metalDrawable->texture());
    // what to do with existing data in texture
    // LoadActionClear: replace with specified clear color
    // LoadActionLoad: keep data
    // LoadActionDontCare: doesn't manage data; undefined data
    cd->setLoadAction(MTL::LoadActionClear);
    cd->setClearColor(MTL::ClearColor(41.0f/255.0f, 42.0f/255.0f, 48.0f/255.0f, 1.0));
    // what to do with rendered data after render pass
    // StoreActionDontCare: doesn't store data in texture; undefined texture data (if you only needed the texture as temp data for the rendering pass)
    // StoreActionStore: stores data in texture
    cd->setStoreAction(MTL::StoreActionStore);

    MTL::RenderCommandEncoder* renderCommandEncoder = metalCommandBuffer->renderCommandEncoder(renderPassDescriptor);
    encodeRenderCommand(renderCommandEncoder);
    // tells Metal those are all the GPU commands
    renderCommandEncoder->endEncoding();

    // this tells Metal to automatically display the drawable after it's rendered
    metalCommandBuffer->presentDrawable(metalDrawable);
    // this tells Metal to execute the command buffer commands
    metalCommandBuffer->commit();
    // this tells Metal to wait until all the commands in the buffer are finished executing before continuing this CPU thread
    // not really needed unless you need to read back data
//    metalCommandBuffer->waitUntilCompleted();

    renderPassDescriptor->release();
}

void Engine::encodeRenderCommand(MTL::RenderCommandEncoder* renderCommandEncoder) {
    renderCommandEncoder->setRenderPipelineState(metalRenderPipelineState);
    // this is the function to give the vertex shader the buffer
    // setVertexBuffer(buffer, offset in bytes from start of buffer, parameter index)
    renderCommandEncoder->setVertexBuffer(triangleVertexBuffer, 0, 0);
    // render command
    // drawPrimitives(primitive type, starting vertex id, num vertices)
    // there is an overload where the second param is a pointer, and so 0 is ambiguous because it can also mean nullptr
    renderCommandEncoder->drawPrimitives(MTL::PrimitiveTypeTriangle, (int)0, 3);
}
