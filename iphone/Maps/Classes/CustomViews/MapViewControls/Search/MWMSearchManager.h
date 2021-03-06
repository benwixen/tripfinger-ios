#import "MWMAlertViewController.h"
#import "MWMSearchTextField.h"
#import "MWMSearchView.h"

typedef NS_ENUM(NSUInteger, MWMSearchManagerState)
{
  MWMSearchManagerStateHidden,
  MWMSearchManagerStateDefault,
  MWMSearchManagerStateTableSearch,
  MWMSearchManagerStateMapSearch
};

@protocol MWMSearchManagerProtocol <NSObject>

@property (nonnull, nonatomic, readonly) MWMAlertViewController * alertController;

- (void)searchViewDidEnterState:(MWMSearchManagerState)state;
- (void)actionDownloadMaps;

@end

@protocol MWMRoutingProtocol;

@interface MWMSearchManager : NSObject

@property (weak, nonatomic) id <MWMSearchManagerProtocol, MWMRoutingProtocol> delegate;
@property (weak, nonatomic) IBOutlet MWMSearchTextField * searchTextField;

@property (nonatomic) MWMSearchManagerState state;

@property (nonnull, nonatomic, readonly) UIView * view;
@property (nonatomic) BOOL initedFromGuide;


- (nullable instancetype)init __attribute__((unavailable("init is not available")));
- (nullable instancetype)initWithParentView:(nonnull UIViewController *)viewController
                                   delegate:(nonnull id<MWMSearchManagerProtocol, MWMSearchViewProtocol, MWMRoutingProtocol>)delegate;

- (void)mwm_refreshUI;
- (void)searchText:(NSString *)text forInputLocale:(NSString *)locale;

#pragma mark - Layout

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
                                duration:(NSTimeInterval)duration;
- (void)viewWillTransitionToSize:(CGSize)size
       withTransitionCoordinator:(nonnull id<UIViewControllerTransitionCoordinator>)coordinator;

@end
