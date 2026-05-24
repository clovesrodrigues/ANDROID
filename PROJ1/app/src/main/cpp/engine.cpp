#include "engine.h"
#include "renderer.h"

namespace engine {
void on_surface_created() { renderer::init(); }
void on_surface_changed(int width, int height) { renderer::resize(width, height); }
void on_draw_frame() { renderer::draw(); }
}
