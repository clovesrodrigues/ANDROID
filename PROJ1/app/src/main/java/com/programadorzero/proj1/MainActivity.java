package com.programadorzero.proj1;

import android.app.Activity;
import android.opengl.GLSurfaceView;
import android.os.Bundle;

public class MainActivity extends Activity {
    static {
        System.loadLibrary("native-lib");
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        GLSurfaceView glView = new GLSurfaceView(this);
        glView.setEGLContextClientVersion(3);
        glView.setRenderer(new NativeRenderer());
        setContentView(glView);
    }

    private static class NativeRenderer implements GLSurfaceView.Renderer {
        public native void nativeOnSurfaceCreated();
        public native void nativeOnSurfaceChanged(int width, int height);
        public native void nativeOnDrawFrame();

        @Override
        public void onSurfaceCreated(javax.microedition.khronos.opengles.GL10 gl,
                                     javax.microedition.khronos.egl.EGLConfig config) {
            nativeOnSurfaceCreated();
        }

        @Override
        public void onSurfaceChanged(javax.microedition.khronos.opengles.GL10 gl, int width, int height) {
            nativeOnSurfaceChanged(width, height);
        }

        @Override
        public void onDrawFrame(javax.microedition.khronos.opengles.GL10 gl) {
            nativeOnDrawFrame();
        }
    }
}
