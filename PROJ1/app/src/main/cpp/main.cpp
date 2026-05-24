#include <jni.h>
#include "engine.h"

extern "C" JNIEXPORT void JNICALL
Java_com_programadorzero_proj1_MainActivity_00024NativeRenderer_nativeOnSurfaceCreated(
    JNIEnv*, jobject) {
    engine::on_surface_created();
}

extern "C" JNIEXPORT void JNICALL
Java_com_programadorzero_proj1_MainActivity_00024NativeRenderer_nativeOnSurfaceChanged(
    JNIEnv*, jobject, jint width, jint height) {
    engine::on_surface_changed(static_cast<int>(width), static_cast<int>(height));
}

extern "C" JNIEXPORT void JNICALL
Java_com_programadorzero_proj1_MainActivity_00024NativeRenderer_nativeOnDrawFrame(
    JNIEnv*, jobject) {
    engine::on_draw_frame();
}
