#include "maps/Framework.hpp"

#include "core/jni_helper.hpp"

#include "platform/Platform.hpp"

#include "storage/index.hpp"

#include "base/logging.hpp"

#include "platform/file_logging.hpp"
#include "platform/settings.hpp"


extern "C"
{
using namespace storage;

JNIEXPORT void JNICALL
Java_com_tripfinger_map_MWMMapView_nativeStorageConnected(JNIEnv * env, jclass clazz)
{
android::Platform::Instance().OnExternalStorageStatusChanged(true);
g_framework->AddLocalMaps();
}

JNIEXPORT void JNICALL
Java_com_tripfinger_map_MWMMapView_nativeStorageDisconnected(JNIEnv * env, jclass clazz)
{
android::Platform::Instance().OnExternalStorageStatusChanged(false);
g_framework->RemoveLocalMaps();
}

JNIEXPORT jboolean JNICALL
        Java_com_tripfinger_map_MWMMapView_nativeCreateEngine(JNIEnv * env, jclass clazz, jobject surface, jint density)
{
return g_framework->CreateDrapeEngine(env, surface, density);
}

JNIEXPORT void JNICALL
Java_com_tripfinger_map_MWMMapView_nativeDestroyEngine(JNIEnv * env, jclass clazz)
{
g_framework->DeleteDrapeEngine();
}

JNIEXPORT jboolean JNICALL
        Java_com_tripfinger_map_MWMMapView_nativeIsEngineCreated(JNIEnv * env, jclass clazz)
{
return g_framework->IsDrapeEngineCreated();
}

JNIEXPORT void JNICALL
Java_com_tripfinger_map_MWMMapView_nativeAttachSurface(JNIEnv * env, jclass clazz, jobject surface)
{
g_framework->AttachSurface(env, surface);
}

JNIEXPORT void JNICALL
Java_com_tripfinger_map_MWMMapView_nativeDetachSurface(JNIEnv * env, jclass clazz)
{
g_framework->DetachSurface();
}

JNIEXPORT void JNICALL
Java_com_tripfinger_map_MWMMapView_nativeSurfaceChanged(JNIEnv * env, jclass clazz, jint w, jint h)
{
g_framework->Resize(w, h);
}

JNIEXPORT void JNICALL
Java_com_tripfinger_map_MWMMapView_nativeOnTouch(JNIEnv * env, jclass clazz, jint action,
jint id1, jfloat x1, jfloat y1,
        jint id2, jfloat x2, jfloat y2,
jint maskedPointer)
{
g_framework->Touch(action,
        android::Framework::Finger(id1, x1, y1),
        android::Framework::Finger(id2, x2, y2), maskedPointer);
}

JNIEXPORT void JNICALL
Java_com_tripfinger_map_MWMMapView_nativeSetupWidget(JNIEnv * env, jclass clazz, jint widget, jfloat x, jfloat y, jint anchor)
{
g_framework->SetupWidget(static_cast<gui::EWidget>(widget), x, y, static_cast<dp::Anchor>(anchor));
}

JNIEXPORT void JNICALL
Java_com_tripfinger_map_MWMMapView_nativeApplyWidgets(JNIEnv * env, jclass clazz)
{
g_framework->ApplyWidgets();
}

JNIEXPORT void JNICALL
Java_com_tripfinger_map_MWMMapView_nativeCleanWidgets(JNIEnv * env, jclass clazz)
{
g_framework->CleanWidgets();
}

} // extern "C"
