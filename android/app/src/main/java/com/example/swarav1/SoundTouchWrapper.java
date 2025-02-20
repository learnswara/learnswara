package com.example.swarav1;

public class SoundTouchWrapper {
    static {
        System.loadLibrary("soundtouch_wrapper");
    }

    private long nativeHandle;

    public SoundTouchWrapper() {
        nativeHandle = createSoundTouch();
    }

    private native long createSoundTouch();
    private native void destroySoundTouch(long handle);

    public void dispose() {
        if (nativeHandle != 0) {
            destroySoundTouch(nativeHandle);
            nativeHandle = 0;
        }
    }

    @Override
    protected void finalize() throws Throwable {
        dispose();
        super.finalize();
    }
} 