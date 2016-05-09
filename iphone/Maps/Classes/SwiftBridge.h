// Generated by Apple Swift version 2.1.1 (swiftlang-700.1.101.15 clang-700.1.81)
#pragma clang diagnostic push

#if defined(__has_include) && __has_include(<swift/objc-prologue.h>)
# include <swift/objc-prologue.h>
#endif

#pragma clang diagnostic ignored "-Wauto-import"
#include <objc/NSObject.h>
#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>

#if defined(__has_include) && __has_include(<uchar.h>)
# include <uchar.h>
#elif !defined(__cplusplus) || __cplusplus < 201103L
typedef uint_least16_t char16_t;
typedef uint_least32_t char32_t;
#endif

typedef struct _NSZone NSZone;

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
#endif
typedef float swift_float2  __attribute__((__ext_vector_type__(2)));
typedef float swift_float3  __attribute__((__ext_vector_type__(3)));
typedef float swift_float4  __attribute__((__ext_vector_type__(4)));
typedef double swift_double2  __attribute__((__ext_vector_type__(2)));
typedef double swift_double3  __attribute__((__ext_vector_type__(3)));
typedef double swift_double4  __attribute__((__ext_vector_type__(4)));
typedef int swift_int2  __attribute__((__ext_vector_type__(2)));
typedef int swift_int3  __attribute__((__ext_vector_type__(3)));
typedef int swift_int4  __attribute__((__ext_vector_type__(4)));
#if defined(__has_feature) && __has_feature(modules)
@import UIKit;
@import CoreGraphics;
@import RealmSwift;
@import MDCSwipeToChoose;
@import CoreLocation;
@import Foundation;
@import Realm;
@import ObjectiveC;
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
@property (nonatomic) BOOL liked;
- (NSURL * __nonnull)getFileUrl;- (nonnull instancetype)init OBJC_DESIGNATED_INITIALIZER;
@end


SWIFT_CLASS("_TtC10Tripfinger21TripfingerAppDelegate")
@interface TripfingerAppDelegate : NSObject
+ (NSString * __nonnull)serverUrl;
+ (void)setServerUrl:(NSString * __nonnull)value;
- (UIWindow * __nonnull)applicationLaunched:(UIApplication * __nonnull)application delegate:(id <UIApplicationDelegate> __nonnull)delegate didFinishLaunchingWithOptions:(NSDictionary * __nullable)launchOptions;
+ (NSArray<TripfingerEntity *> * __nonnull)getPoisForArea:(CLLocationCoordinate2D)topLeft bottomRight:(CLLocationCoordinate2D)bottomRight zoomLevel:(NSInteger)zoomLevel;
+ (NSArray<TripfingerEntity *> * __nonnull)getPoisForArea:(CLLocationCoordinate2D)topLeft bottomRight:(CLLocationCoordinate2D)bottomRight category:(NSInteger)category;
+ (TripfingerEntity * __nonnull)getPoiById:(int32_t)id;
+ (TripfingerEntity * __nonnull)getListingById:(int32_t)id;
+ (TripfingerEntity * __nonnull)getListingByCoordinate:(CLLocationCoordinate2D)coord;
+ (BOOL)coordinateExists:(CLLocationCoordinate2D)coord;
+ (NSInteger)nameToCategoryId:(NSString * __nonnull)name;
+ (void)displayPlacePage:(NSArray<UIView *> * __nonnull)views;
+ (void)bookmarkAdded;
+ (void)bookmarkRemoved;
- (nonnull instancetype)init OBJC_DESIGNATED_INITIALIZER;
@end

SWIFT_CLASS("_TtC10Tripfinger17PlacePageInfoCell")
@interface PlacePageInfoCell : UITableViewCell
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
