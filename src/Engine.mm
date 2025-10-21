//
//  Engine.mm
//  Engine Metal
//
//  Created by Max Shi on 10/20/25.
//

#include "Engine.hpp"

void Engine::init() {
    initDevice();
    initWindow();
}

void Engine::run() {
    while (!glfwWindowShouldClose(glfwWindow)) {
        glfwPollEvents();
    }
    glfwTerminate();
}

void Engine::cleanup() {
    glfwTerminate();
    metalDevice->release();
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
    // this is an Objective-C typecast
    // __bridge id<type> tells Objective-C to convert C++ object metalDevice to Objective-C type MTLDevice
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
