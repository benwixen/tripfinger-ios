// Generated by Apple Swift version 2.2 (swiftlang-703.0.18.8 clang-703.0.31)
#pragma clang diagnostic push

#if defined(__has_include) && __has_include(<swift/objc-prologue.h>)
# include <swift/objc-prologue.h>
#endif

#pragma clang diagnostic ignored "-Wauto-import"
#include <objc/NSObject.h>
#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>

#if !defined(SWIFT_TYPEDEFS)
# define SWIFT_TYPEDEFS 1
# if defined(__has_include) && __has_include(<uchar.h>)
#  include <uchar.h>
# elif !defined(__cplusplus) || __cplusplus < 201103L
typedef uint_least16_t char16_t;
typedef uint_least32_t char32_t;
# endif
typedef float swift_float2  __attribute__((__ext_vector_type__(2)));
typedef float swift_float3  __attribute__((__ext_vector_type__(3)));
typedef float swift_float4  __attribute__((__ext_vector_type__(4)));
typedef double swift_double2  __attribute__((__ext_vector_type__(2)));
typedef double swift_double3  __attribute__((__ext_vector_type__(3)));
typedef double swift_double4  __attribute__((__ext_vector_type__(4)));
typedef int swift_int2  __attribute__((__ext_vector_type__(2)));
typedef int swift_int3  __attribute__((__ext_vector_type__(3)));
typedef int swift_int4  __attribute__((__ext_vector_type__(4)));
#endif

#if !defined(SWIFT_PASTE)
# define SWIFT_PASTE_HELPER(x, y) x##y
# define SWIFT_PASTE(x, y) SWIFT_PASTE_HELPER(x, y)
#endif
#if !defined(SWIFT_METATYPE)
# define SWIFT_METATYPE(X) Class
#endif

#if defined(__has_attribute) && __has_attribute(objc_runtime_name)
# define SWIFT_RUNTIME_NAME(X) __attribute__((objc_runtime_name(X)))
#else
# define SWIFT_RUNTIME_NAME(X)
#endif
#if defined(__has_attribute) && __has_attribute(swift_name)
# define SWIFT_COMPILE_NAME(X) __attribute__((swift_name(X)))
#else
# define SWIFT_COMPILE_NAME(X)
#endif
#if !defined(SWIFT_CLASS_EXTRA)
# define SWIFT_CLASS_EXTRA
#endif
#if !defined(SWIFT_PROTOCOL_EXTRA)
# define SWIFT_PROTOCOL_EXTRA
#endif
#if !defined(SWIFT_ENUM_EXTRA)
# define SWIFT_ENUM_EXTRA
#endif
#if !defined(SWIFT_CLASS)
# if defined(__has_attribute) && __has_attribute(objc_subclassing_restricted)
#  define SWIFT_CLASS(SWIFT_NAME) SWIFT_RUNTIME_NAME(SWIFT_NAME) __attribute__((objc_subclassing_restricted)) SWIFT_CLASS_EXTRA
#  define SWIFT_CLASS_NAMED(SWIFT_NAME) __attribute__((objc_subclassing_restricted)) SWIFT_COMPILE_NAME(SWIFT_NAME) SWIFT_CLASS_EXTRA
# else
#  define SWIFT_CLASS(SWIFT_NAME) SWIFT_RUNTIME_NAME(SWIFT_NAME) SWIFT_CLASS_EXTRA
#  define SWIFT_CLASS_NAMED(SWIFT_NAME) SWIFT_COMPILE_NAME(SWIFT_NAME) SWIFT_CLASS_EXTRA
# endif
#endif

#if !defined(SWIFT_PROTOCOL)
# define SWIFT_PROTOCOL(SWIFT_NAME) SWIFT_RUNTIME_NAME(SWIFT_NAME) SWIFT_PROTOCOL_EXTRA
# define SWIFT_PROTOCOL_NAMED(SWIFT_NAME) SWIFT_COMPILE_NAME(SWIFT_NAME) SWIFT_PROTOCOL_EXTRA
#endif

#if !defined(SWIFT_EXTENSION)
# define SWIFT_EXTENSION(M) SWIFT_PASTE(M##_Swift_, __LINE__)
#endif

#if !defined(OBJC_DESIGNATED_INITIALIZER)
# if defined(__has_attribute) && __has_attribute(objc_designated_initializer)
#  define OBJC_DESIGNATED_INITIALIZER __attribute__((objc_designated_initializer))
# else
#  define OBJC_DESIGNATED_INITIALIZER
# endif
#endif
#if !defined(SWIFT_ENUM)
# define SWIFT_ENUM(_type, _name) enum _name : _type _name; enum SWIFT_ENUM_EXTRA _name : _type
# if defined(__has_feature) && __has_feature(generalized_swift_name)
#  define SWIFT_ENUM_NAMED(_type, _name, SWIFT_NAME) enum _name : _type _name SWIFT_COMPILE_NAME(SWIFT_NAME); enum SWIFT_COMPILE_NAME(SWIFT_NAME) SWIFT_ENUM_EXTRA _name : _type
# else
#  define SWIFT_ENUM_NAMED(_type, _name, SWIFT_NAME) SWIFT_ENUM(_type, _name)
# endif
#endif
#if defined(__has_feature) && __has_feature(modules)
@import UIKit;
@import CoreGraphics;
@import Foundation;
@import MDCSwipeToChoose;
@import ObjectiveC;
@import CoreLocation;
#endif

#pragma clang diagnostic ignored "-Wproperty-attribute-mismatch"
#pragma clang diagnostic ignored "-Wduplicate-method-arg"
@class UILabel;
@class UIButton;
@class SimplePOI;
@class NSCoder;

@class UIApplication;
@protocol UIApplicationDelegate;
@class UIWindow;

SWIFT_CLASS("_TtC10Tripfinger16TripfingerEntity")
@interface TripfingerEntity : NSObject
@property (nonatomic) double lat;
@property (nonatomic) double lon;
@property (nonatomic) int32_t identifier;
@property (nonatomic) int32_t type;
@property (nonatomic) NSInteger category;
@property (nonatomic, copy) NSString * __null_unspecified tripfingerId;
@property (nonatomic, copy) NSString * __null_unspecified name;
@property (nonatomic, copy) NSString * __null_unspecified phone;
@property (nonatomic, copy) NSString * __null_unspecified address;
@property (nonatomic, copy) NSString * __null_unspecified website;
@property (nonatomic, copy) NSString * __null_unspecified email;
@property (nonatomic, copy) NSString * __null_unspecified content;
@property (nonatomic, copy) NSString * __null_unspecified price;
@property (nonatomic, copy) NSString * __null_unspecified openingHours;
@property (nonatomic, copy) NSString * __null_unspecified directions;
@property (nonatomic, copy) NSString * __null_unspecified url;
@property (nonatomic, copy) NSString * __null_unspecified imageDescription;
@property (nonatomic, copy) NSString * __null_unspecified license;
@property (nonatomic, copy) NSString * __null_unspecified artist;
@property (nonatomic, copy) NSString * __null_unspecified originalUrl;
@property (nonatomic) BOOL offline;
@property (nonatomic) BOOL liked;
- (NSURL * __nonnull)getFileUrl;- (nonnull instancetype)init OBJC_DESIGNATED_INITIALIZER;
@end


SWIFT_CLASS("_TtC10Tripfinger21TripfingerAppDelegate")
@interface TripfingerAppDelegate : NSObject
+ (NSString * __nonnull)serverUrl;
+ (void)setServerUrl:(NSString * __nonnull)value;
+ (UIWindow * __nonnull)applicationLaunched:(UIApplication * __nonnull)application delegate:(id <UIApplicationDelegate> __nonnull)delegate didFinishLaunchingWithOptions:(NSDictionary * __nullable)launchOptions;
+ (void)applicationDidBecomeActive:(UIApplication * __nonnull)application;
+ (BOOL)application:(UIApplication * __nonnull)application openURL:(NSURL * __nonnull)url sourceApplication:(NSString * __nonnull)
sourceApplication annotation:(id __nonnull)annotation;
+ (void)applicationDidEnterBackground:(UIApplication * __nonnull)application;
+ (void)application:(UIApplication * __nonnull)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings;
+ (void)application:(UIApplication * __nonnull)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken;
+ (void)application:(UIApplication * __nonnull)application didReceiveRemoteNotification:(NSDictionary * __nonnull)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler;
+ (NSArray<TripfingerEntity *> * __nonnull)getPoisForArea:(CLLocationCoordinate2D)topLeft bottomRight:(CLLocationCoordinate2D)bottomRight zoomLevel:(NSInteger)zoomLevel;
+ (NSArray<TripfingerEntity *> * __nonnull)getPoisForArea:(CLLocationCoordinate2D)topLeft bottomRight:(CLLocationCoordinate2D)bottomRight category:(NSInteger)category;
+ (TripfingerEntity * __nonnull)getOnlineListingById:(NSString * __nonnull)listingId;
+ (TripfingerEntity * __nonnull)getOfflineListingById:(NSString * __nonnull)listingId;
+ (BOOL)isListingOffline:(NSString * __nonnull)listingId;
+ (TripfingerEntity * __nonnull)getListingByCoordinate:(CLLocationCoordinate2D)coord;
+ (NSArray<TripfingerEntity *> * __nonnull)poiSearch:(NSString * __nonnull)query includeRegions:(BOOL)includeRegions;
+ (BOOL)coordinateExists:(CLLocationCoordinate2D)coord;
+ (NSInteger)nameToCategoryId:(NSString * __nonnull)name;
+ (void)displayPlacePage:(NSArray<UIView *> * __nonnull)views entity:(TripfingerEntity * __nonnull)entity countryMwmId:(NSString * __nonnull)countryMwmId;
+ (void)bookmarkAdded:(NSString * __nonnull)listingId;
+ (void)bookmarkRemoved:(NSString * __nonnull)listingId;
+ (void)selectedSearchResult:(TripfingerEntity * __nonnull)searchResult failure:(void (^ __nonnull)(void))failure stopSpinner:(void (^ __nonnull)(void))stopSpinner;
+ (BOOL)isCountryDownloaded:(NSString * __nonnull)countryName;
+ (NSInteger)downloadStatus:(NSString * __nonnull)mwmCountryId;
+ (NSInteger)countrySize:(NSString * __nonnull)mwmCountryId;
+ (void)updateCountry:(NSString * _Nonnull)mwmCountryId downloadStarted:(void (^ _Nonnull)(void))downloadStarted;
+ (void)cancelDownload:(NSString * __nonnull)mwmRegionId;
+ (void)deleteCountry:(NSString * __nonnull)mwmCountryId;
+ (void)purchaseCountry:(NSString * _Nonnull)mwmCountryId downloadStarted:(void (^ _Nonnull)(void))downloadStarted;
+ (BOOL)isReleaseMode;
+ (BOOL)getDraftMode;
+ (void)setDraftMode:(BOOL)draftMode;
- (nonnull instancetype)init OBJC_DESIGNATED_INITIALIZER;
@end

SWIFT_PROTOCOL("_TtP10Tripfinger25PlacePageInfoCellDelegate_")
@protocol PlacePageInfoCellDelegate
- (void)navigatedToGuide;
@end


SWIFT_CLASS("_TtC10Tripfinger17PlacePageInfoCell")
@interface PlacePageInfoCell : UITableViewCell
@property (nonatomic, strong) id <PlacePageInfoCellDelegate> __nullable delegate;
@property (nonatomic) BOOL contentSet;
@property (nonatomic, readonly, strong) UIImageView * __nonnull myImageView;
@property (nonatomic, readonly, strong) UITextView * __nonnull descriptionText;
@property (nonatomic, readonly, strong) UILabel * __nonnull priceLabel;
@property (nonatomic, readonly, strong) UITextView * __nonnull priceText;
@property (nonatomic, readonly, strong) UILabel * __nonnull directionsLabel;
@property (nonatomic, readonly, strong) UITextView * __nonnull directionsText;
@property (nonatomic, readonly) CGFloat myWidth;
- (nonnull instancetype)initWithWidth:(CGFloat)width OBJC_DESIGNATED_INITIALIZER;
- (nullable instancetype)initWithCoder:(NSCoder * __nonnull)aDecoder OBJC_DESIGNATED_INITIALIZER;
- (void)setContentFromGuideItem:(TripfingerEntity * __nonnull)tripfingerEntity;
@end
