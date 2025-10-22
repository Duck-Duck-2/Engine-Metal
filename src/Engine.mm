//
//  Engine.mm
//  Engine Metal
//
//  Created by Max Shi on 10/20/25.
//

#include "Engine.hpp"

Engine::Engine() {
    initDevice();
    initWindow();
    
    createTriangle();
}

void Engine::run() {
    while (!glfwWindowShouldClose(glfwWindow)) {
        glfwPollEvents();
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
    glfwWindow = glfwCreateWindow(800, 600, "Metal Engine", NULL, NULL);
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
    triangleVertexBuffer = metalDevice->newBuffer(&triangleVertices,
                                                  sizeof(triangleVertices),
                                                  MTL::ResourceStorageModeShared);
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

    // creates the render pipeline descriptor, which represents the render pipeline and handles its config
    // allocations the memory and then initializes it
    MTL::RenderPipelineDescriptor* renderPipelineDescriptor = MTL::RenderPipelineDescriptor::alloc()->init();
    renderPipelineDescriptor->setVertexFunction(vertexShader);
    renderPipelineDescriptor->setFragmentFunction(fragmentShader);
    assert(renderPipelineDescriptor);
    MTL::PixelFormat pixelFormat = (MTL::PixelFormat)metalLayer.pixelFormat;
    // render pipelines can have multiple render targets (in this case, we're only rendering color, so 1)
    // render targets are just buffers
    // attachments are just buffers that are attached to a render pass, making them render targets for that pass
    // attachments can be color or depth
    // this specifies the color attachment's pixel format
    renderPipelineDescriptor->colorAttachments()->object(0)->setPixelFormat(pixelFormat);

    NS::Error* error;
    metalRenderPSO = metalDevice->newRenderPipelineState(renderPipelineDescriptor, &error);
    if (error) {
        std::cerr << error->localizedDescription() << std::endl;
        error->release();
    }
    
    vertexShader->release();
    fragmentShader->release();
    renderPipelineDescriptor->release();
}
