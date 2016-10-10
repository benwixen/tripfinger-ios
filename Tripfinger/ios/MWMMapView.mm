#import <UIKit/UIKit.h>
#import "Framework.h"
#import "MWMMapView.h"
#import "MWMFrameworkListener.h"
#import "MWMFrameworkObservers.h"

@interface MWMMapView ()<MWMFrameworkDrapeObserver, MWMFrameworkStorageObserver>
@end

@implementation MWMMapView{
  TCountryId currentCountryId;
}
  
+ (instancetype)sharedInstance {
  static MWMMapView *sharedInstance = nil;
  static dispatch_once_t onceToken;
  if (sharedInstance != nil) {
    [sharedInstance viewFetched];
  }
  dispatch_once(&onceToken, ^{
    sharedInstance = [[MWMMapView alloc] initWithFrame:CGRectZero];
  });
  [(EAGLView *)sharedInstance setPresentAvailable:YES];
  return sharedInstance;
}
  
- (id)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  currentCountryId = kInvalidCountryId;
  [self initializeFramework];
  return self;
}
  
- (void)initializeFramework {
  Framework & f = GetFramework();
  
  f.SetMapSelectionListeners([self](place_page::Info const & info) {
    int lat = (int)(info.GetLatLon().lat * 1000000 + 0.5);
    int lon = (int)(info.GetLatLon().lon * 1000000 + 0.5);
    self.onMapObjectSelected(@{
                               @"info": @{
                                   @"title": @(info.GetTitle().c_str()),
                                   @"address": @(info.GetAddress().c_str()),
                                   @"lat": [NSNumber numberWithInt:lat],
                                   @"lon": [NSNumber numberWithInt:lon],
                                   @"category": @(info.GetSubtitle().c_str()),
                                   },
                               });
  }, [self](bool switchFullScreen) {
    self.onMapObjectDeselected(@{@"switchFullScreen": switchFullScreen ? @"true" : @"false"});
  });
  
  f.SetMyPositionModeListener([self](location::EMyPositionMode mode) {
    NSString* modeString = [self processMyPositionStateModeEvent:mode];
    if (self.onLocationStateChanged != nil) {
      self.onLocationStateChanged(@{@"locationState": modeString});
    }
  });
  
  f.SetPoiSupplierFunction([self](TripfingerMarkParams& params) {
    return [self poiSupplier:params];
  });
  
  f.SetCoordinateCheckerFunction([self](ms::LatLon latlon) {
    return [self coordinateChecker:latlon];
  });
  
  [MWMFrameworkListener addObserver:self];
}
  
  - (void)processViewportCountryEvent:(TCountryId const &)countryId {
    currentCountryId = countryId;
    [self sendZoomedInToMapRegionEvent:countryId];
  }
  
  - (void)sendZoomedInToMapRegionEvent:(TCountryId)mapRegionId {
    if (mapRegionId != kInvalidCountryId) {
      NodeAttrs nodeAttrs;
      auto & s = GetFramework().Storage();
      s.GetNodeAttrs(mapRegionId, nodeAttrs);
      if (!nodeAttrs.m_present) {
        BOOL const isMultiParent = nodeAttrs.m_parentInfo.size() > 1;
        BOOL const noParrent = (nodeAttrs.m_parentInfo[0].m_id == s.GetRootId());
        BOOL const sameName = nodeAttrs.m_nodeLocalName == nodeAttrs.m_parentInfo[0].m_localName;
        BOOL const hideParent = (noParrent || isMultiParent || sameName);
        NSString* parentName = nil;
        if (!hideParent) {
          parentName = @(nodeAttrs.m_parentInfo[0].m_localName.c_str());
        }
        if (self.onZoomedInToMapRegion != nil) {
          self.onZoomedInToMapRegion(@{
                                       @"mapRegion": @{
                                           @"mapRegionId": @(mapRegionId.c_str()),
                                           @"localName": @(nodeAttrs.m_nodeLocalName.c_str()),
                                           @"downloadSize": formattedSize(nodeAttrs.m_mwmSize),
                                           @"parentName": parentName != nil ? parentName : [NSNull null],
                                           @"status": [MWMMapView nodeStatusToString:nodeAttrs.m_status],
                                           @"progress": [NSNumber numberWithInteger:nodeAttrs.m_downloadingProgress.first],
                                           @"size": [NSNumber numberWithInteger:nodeAttrs.m_downloadingProgress.second],
                                           },
                                       });
        }
        return;
      }
    }
    self.onZoomedOutOfMapRegion(@{});
}
  
  + (NSString*)nodeStatusToString:(storage::NodeStatus)status {
    switch (status) {
      case storage::NodeStatus::Downloading:
      return @"downloading";
      case storage::NodeStatus::Undefined:
      return @"undefined";
      case storage::NodeStatus::OnDisk:
      return @"on_disk";
      case storage::NodeStatus::OnDiskOutOfDate:
      return @"on_disk_out_of_date";
      case storage::NodeStatus::InQueue:
      return @"in_queue";
      case storage::NodeStatus::NotDownloaded:
      return @"not_downloaded";
      case storage::NodeStatus::Partly:
      return @"partly_downloaded";
      case storage::NodeStatus::Error:
      return @"error";
    }
  }
  
- (NSString*)processMyPositionStateModeEvent:(location::EMyPositionMode)mode {
  switch (mode) {
    case location::MODE_UNKNOWN_POSITION:
    case location::MODE_NOT_FOLLOW:
    return @"not_located";
    case location::MODE_PENDING_POSITION:
    return @"pending";
    case location::MODE_FOLLOW:
    return @"located";
    case location::MODE_ROTATE_AND_FOLLOW:
    return @"following";
  }
}
  
#pragma mark - MWMFrameworkStorageObserver
  
- (void)processCountryEvent:(TCountryId const &)countryId {
  if (countryId == currentCountryId) {
    [self sendZoomedInToMapRegionEvent:countryId];
  }
}
  
- (void)processCountry:(TCountryId const &)countryId progress:(TLocalAndRemoteSize const &)progress {
  if (countryId == currentCountryId) {
    [self sendZoomedInToMapRegionEvent:countryId];
  }
}
  
- (vector<TripfingerMark>)poiSupplier:(TripfingerMarkParams &)params {
  vector<TripfingerMark> tripfingerVector;
  return tripfingerVector;
}
  
- (bool)coordinateChecker:(ms::LatLon)coord {
  return NO;
}
  
- (void)layoutSubviews {
  [super layoutSubviews];
  
  [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
  
  GetFramework().InvalidateRendering();
}
  
- (void)viewFetched {
  GetFramework().InvalidateRendering();
}
  
- (void)onEnterBackground {
  // Save state and notify about entering background.
  GetFramework().EnterBackground();
}
  
- (void)onGetFocus:(BOOL)isOnFocus {
  [self setPresentAvailable:isOnFocus];
}
  
  
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
  [self sendTouchType:df::TouchEvent::TOUCH_DOWN withTouches:touches andEvent:event];
}
  
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
  [self sendTouchType:df::TouchEvent::TOUCH_MOVE withTouches:nil andEvent:event];
}
  
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
  [self sendTouchType:df::TouchEvent::TOUCH_UP withTouches:touches andEvent:event];
}
  
- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
  [self sendTouchType:df::TouchEvent::TOUCH_CANCEL withTouches:touches andEvent:event];
}
  
- (void)sendTouchType:(df::TouchEvent::ETouchType)type withTouches:(NSSet *)touches andEvent:(UIEvent *)event {
  NSArray * allTouches = [[event allTouches] allObjects];
  if ([allTouches count] < 1)
  return;
  
  CGFloat const scaleFactor = self.contentScaleFactor;
  
  df::TouchEvent e;
  UITouch * touch = [allTouches objectAtIndex:0];
  CGPoint const pt = [touch locationInView:self];
  e.m_type = type;
  e.m_touches[0].m_id = reinterpret_cast<int64_t>(touch);
  e.m_touches[0].m_location = m2::PointD(pt.x * scaleFactor, pt.y * scaleFactor);
  if ([self hasForceTouch])
  e.m_touches[0].m_force = touch.force / touch.maximumPossibleForce;
  if (allTouches.count > 1)
  {
    UITouch * touch = [allTouches objectAtIndex:1];
    CGPoint const pt = [touch locationInView:self];
    e.m_touches[1].m_id = reinterpret_cast<int64_t>(touch);
    e.m_touches[1].m_location = m2::PointD(pt.x * scaleFactor, pt.y * scaleFactor);
    if ([self hasForceTouch])
    e.m_touches[1].m_force = touch.force / touch.maximumPossibleForce;
  }
  
  NSArray * toggledTouches = [touches allObjects];
  if (toggledTouches.count > 0)
  [self checkMaskedPointer:[toggledTouches objectAtIndex:0] withEvent:e];
  
  if (toggledTouches.count > 1)
  [self checkMaskedPointer:[toggledTouches objectAtIndex:1] withEvent:e];
  
  Framework & f = GetFramework();
  f.TouchEvent(e);
}
  
- (BOOL)hasForceTouch {
  if (isIOS8) {
    return NO;
    
  }
  return self.traitCollection.forceTouchCapability == UIForceTouchCapabilityAvailable;
}
  
- (void)checkMaskedPointer:(UITouch *)touch withEvent:(df::TouchEvent &)e
  {
    int64_t id = reinterpret_cast<int64_t>(touch);
    int8_t pointerIndex = df::TouchEvent::INVALID_MASKED_POINTER;
    if (e.m_touches[0].m_id == id)
    pointerIndex = 0;
    else if (e.m_touches[1].m_id == id)
    pointerIndex = 1;
    
    if (e.GetFirstMaskedPointer() == df::TouchEvent::INVALID_MASKED_POINTER)
    e.SetFirstMaskedPointer(pointerIndex);
    else
    e.SetSecondMaskedPointer(pointerIndex);
  }
  
- (void)onTerminate
  {
    [self deallocateNative];
  }
  
- (void)setLocation:(NSDictionary *)location {
  if (location == nil) {
    return;
  }
  auto const info = [MWMMapView gpsInfoFromLocation:location];
  Framework & frm = GetFramework();
  frm.OnLocationUpdate(info);
}
  
+ (location::GpsInfo)gpsInfoFromLocation:(NSDictionary *)location {
  location::GpsInfo info;
  info.m_source = location::EAppleNative;
  
  info.m_latitude = [[[location objectForKey:@"coords"] objectForKey:@"latitude"] doubleValue];
  info.m_longitude = [[[location objectForKey:@"coords"] objectForKey:@"longitude"] doubleValue];
  info.m_timestamp = [[location objectForKey:@"timestamp"] doubleValue];
  
  double accuracy = [[[location objectForKey:@"coords"] objectForKey:@"accuracy"] doubleValue];
  if (accuracy >= 0.0) {
    info.m_horizontalAccuracy = accuracy;
    info.m_verticalAccuracy = accuracy;
  }

  double altitudeAccuracy = [[[location objectForKey:@"coords"] objectForKey:@"altitudeAccuracy"] doubleValue];
  double altitude = [[[location objectForKey:@"coords"] objectForKey:@"altitude"] doubleValue];
  if (altitudeAccuracy >= 0.0)
  {
    info.m_altitude = altitude;
  }

  double heading = [[[location objectForKey:@"coords"] objectForKey:@"heading"] doubleValue];
  if (heading >= 0.0) {
    info.m_bearing = heading;
  }
  
  double speed = [[[location objectForKey:@"coords"] objectForKey:@"speed"] doubleValue];
  if (speed >= 0.0) {
    info.m_speed = speed;
  }
  
  return info;
}

- (void)setHeading:(double)heading {
  auto const info = [MWMMapView compasInfoFromHeading:heading];
  Framework & frm = GetFramework();
  frm.OnCompassUpdate(info);
}

+ (location::CompassInfo)compasInfoFromHeading:(double)heading {
  location::CompassInfo info;
  info.m_bearing = my::DegToRad(heading);
  return info;
}
  
@end

@interface MWMMapViewManager : RCTViewManager
@end

@implementation MWMMapViewManager
  
  RCT_EXPORT_MODULE()
  
  RCT_EXPORT_METHOD(deactivateMapSelection) {
    GetFramework().DeactivateMapSelection(false);
  }
  
  RCT_EXPORT_METHOD(switchToNextPositionMode) {
    GetFramework().SwitchMyPositionNextMode();
  }
  
  RCT_EXPORT_METHOD(downloadMapRegion:(NSString*)regionId) {
    dispatch_async(dispatch_get_main_queue(), ^{
      GetFramework().Storage().DownloadNode([regionId UTF8String]);
    });
  }
  
  RCT_EXPORT_METHOD(cancelMapRegionDownload:(NSString*)regionId) {
    GetFramework().Storage().CancelDownloadNode([regionId UTF8String]);
  }
  
  RCT_EXPORT_METHOD(zoomIn) {
    GetFramework().Scale(Framework::SCALE_MAG, true);
  }

  RCT_EXPORT_METHOD(zoomOut) {
    GetFramework().Scale(Framework::SCALE_MIN, true);
  }

  RCT_EXPORT_VIEW_PROPERTY(onMapObjectSelected, RCTBubblingEventBlock)
  RCT_EXPORT_VIEW_PROPERTY(onMapObjectDeselected, RCTBubblingEventBlock)
  RCT_EXPORT_VIEW_PROPERTY(onLocationStateChanged, RCTBubblingEventBlock)
  RCT_EXPORT_VIEW_PROPERTY(onZoomedInToMapRegion, RCTBubblingEventBlock)
  RCT_EXPORT_VIEW_PROPERTY(onZoomedOutOfMapRegion, RCTBubblingEventBlock)
  RCT_EXPORT_VIEW_PROPERTY(location, NSDictionary)
  RCT_EXPORT_VIEW_PROPERTY(heading, double)

- (UIView *)view {
  return [MWMMapView sharedInstance];
}
  
@end
