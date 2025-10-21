//
//  MetalImplementation.cpp
//  Engine Metal
//
//  Created by Max Shi on 10/20/25.
//

/*
 this works because by enabling these maacros, the implementations are defined in this file during compilation
 therefore, other files that imported these headers will be able to access the implementations because it was defined here
 */

#define NS_PRIVATE_IMPLEMENTATION
#define CA_PRIVATE_IMPLEMENTATION
#define MTL_PRIVATE_IMPLEMENTATION
#include <Foundation/Foundation.hpp>
#include <Metal/Metal.hpp>
#include <QuartzCore/QuartzCore.hpp>
