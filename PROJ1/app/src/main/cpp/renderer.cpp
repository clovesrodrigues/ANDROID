#include "renderer.h"
#include <GLES3/gl3.h>

namespace renderer {
void init() { glClearColor(0.10f, 0.14f, 0.22f, 1.0f); }
void resize(int width, int height) { glViewport(0, 0, width, height); }
void draw() { glClear(GL_COLOR_BUFFER_BIT); }
}
