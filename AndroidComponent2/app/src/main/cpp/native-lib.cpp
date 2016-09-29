#include "maps/Framework.hpp"
#include "core/jni_helper.hpp"
#include "platform/Platform.hpp"

extern "C"
{
    JNIEXPORT void JNICALL
    Java_com_tripfinger_androidcomponent2_MwmApplication_nativeInitPlatform(JNIEnv * env, jobject thiz, jstring apkPath, jstring storagePath, jstring tmpPath,
                                                               jstring obbGooglePath, jstring flavorName, jstring buildType, jboolean isYota, jboolean isTablet)
    {

        android::Platform::Instance().Initialize(env, thiz, apkPath, storagePath, tmpPath, obbGooglePath, flavorName, buildType, isYota, isTablet);
    }

    JNIEXPORT void JNICALL
    Java_com_tripfinger_androidcomponent2_MwmApplication_nativeInitFramework(JNIEnv * env, jclass clazz)
    {
        if (!g_framework)
            g_framework = new android::Framework();
    }


    JNIEXPORT void JNICALL
    Java_com_tripfinger_androidcomponent2_MwmApplication_nativeProcessFunctor(JNIEnv * env, jclass clazz, jlong functorPointer)
    {
        android::Platform::Instance().ProcessFunctor(functorPointer);
    }

jstring
    Java_com_tripfinger_androidcomponent2_MainActivity_stringFromJNI(
            JNIEnv* env,
            jobject /* this */) {
        std::string hello = "Hello from C plus plus";
        return env->NewStringUTF(hello.c_str());
    }

}
