//
//  Main.mm
//  Engine Metal
//
//  Created by Max Shi on 10/20/25.
//

#include <iostream>
#include "Engine.hpp"

int main() {
    Engine engine;
    engine.init();
    engine.run();
    engine.cleanup();

    return EXIT_SUCCESS;
}
