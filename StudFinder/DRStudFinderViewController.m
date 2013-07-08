//
//  DRViewController.m
//  StudFinder
//
//  Created by Danny Ricciotti on 7/8/13.
//  Copyright (c) 2013 Danny Ricciotti. All rights reserved.
//

#import "DRStudFinderViewController.h"
#import "GraphView.h"

typedef enum {
    FinderStateNone = 0,
    FinderStateHoldStill,
    FinderStatePanWall,
    FinderStateFound
} FinderState;

static const double kHoldStillAccelerationLevel = 1.1;

static const NSTimeInterval kUIUpdateInterval = 1/20;

// sign flipped!
static const double kMagneticFieldNone = 180;
static const double kMagneticFieldFull = 300;
static const double kMagneticFieldRange = kMagneticFieldFull - kMagneticFieldNone;

////////////////////////////////////////////////////////////////////////////////

@interface DRStudFinderViewController ()

@property (nonatomic) FinderState state;

// Magnetic
@property (nonatomic) CLLocationManager *locationManager;
@property (nonatomic) double m;
@property (nonatomic) NSInteger axis;

// Motion
@property (nonatomic) CMMotionManager *motionManager;
@property (nonatomic) BOOL motionManagerOn;
@property (nonatomic) BOOL isMovingTooMuch;

// Debug UI
@property (nonatomic) GraphView *graphView;
@property (nonatomic) UILabel *xLabel;
@property (nonatomic) UILabel *yLabel;
@property (nonatomic) UILabel *zLabel;
@end

////////////////////////////////////////////////////////////////////////////////

@implementation DRStudFinderViewController

#pragma mark - Life Cycle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.locationManager = [[CLLocationManager alloc] init];
        self.motionManager = [[CMMotionManager alloc] init];
        self.state = FinderStateNone;
        self.isMovingTooMuch = NO;
        self.m = 0;
        self.axis = 2;  // Z
    }
    return self;
}

- (void)dealloc
{
    self.locationManager.delegate = nil;
    self.motionManagerOn = NO;  // stops it.
}

#pragma mark - UIViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor blackColor];
    
    // check if the hardware has a compass
	if ([CLLocationManager headingAvailable] == NO) {
		// No compass is available. This application cannot function without a compass,
        // so a dialog will be displayed and no magnetic data will be measured.
        self.locationManager = nil;
        UIAlertView *noCompassAlert = [[UIAlertView alloc] initWithTitle:@"No Compass!" message:@"This device does not have the ability to measure magnetic fields." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [noCompassAlert show];
	} else {
        // heading service configuration
        self.locationManager.headingFilter = kCLHeadingFilterNone;
        
        // setup delegate callbacks
        self.locationManager.delegate = self;
        
        // start the compass
        [self.locationManager startUpdatingHeading];
    }
    
//    self.graphView = [[GraphView alloc] initWithFrame:CGRectMake(0, 0, 286, 134)];
//    [self.view addSubview:self.graphView];
    
    self.xLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 320, 50)];
    self.yLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 50, 320, 50)];
    self.zLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 100, 320, 50)];
    [self.view addSubview:self.xLabel];
    [self.view addSubview:self.yLabel];
    [self.view addSubview:self.zLabel];
    
    //
    [self.view addSubview:self.holdStillView];
    
    // Initial state
    if ( self.state == FinderStateNone ) {
        self.state = FinderStatePanWall;
    }
    
    [self.motionManager startMagnetometerUpdatesToQueue:[NSOperationQueue mainQueue] withHandler:^(CMMagnetometerData *magnetometerData, NSError *error) {
        [self _didReceiveMagData:magnetometerData];
    }];
    
    [self setMotionManagerOn:YES];
    
    // todo: invalidate in dealloc
    [NSTimer scheduledTimerWithTimeInterval:kUIUpdateInterval target:self selector:@selector(_updateMag) userInfo:nil repeats:YES];
}

- (void)_didReceiveMagData:(CMMagnetometerData *)magnetometerData
{
    CMMagneticField field = magnetometerData.magneticField;
    
//    NSLog(@"X=%.1f, Y=%.1f, Z=%.1f", field.x, field.y, field.z);
    
    // Update the labels with the raw x, y, and z values.
	[self.xLabel setText:[NSString stringWithFormat:@"%.1f", field.x]];
	[self.yLabel setText:[NSString stringWithFormat:@"%.1f", field.y]];
	[self.zLabel setText:[NSString stringWithFormat:@"%.1f", field.z]];
    
    double value = 0; // normalize to be positive
    if ( self.axis == 2 ) {
        value = field.z;
    } else {
        value = (self.axis==0)?field.x:field.y;
    }
    
    value = -value; // make positive
    
    double a = value - kMagneticFieldNone;
    double range = a / kMagneticFieldRange;
    range = MIN(1,range);
    range = MAX(0, range);
    NSLog(@"M= %.1f, a=%.1f, axis=%d,value=%.1f", range, a,self.axis,value);
    
    self.m = range;
}

#pragma mark - CLLocationManagerDelegate

// This delegate method is invoked when the location manager has heading data.
- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)heading {

//    // Update the labels with the raw x, y, and z values.
//	[self.xLabel setText:[NSString stringWithFormat:@"%.1f", heading.x]];
//	[self.yLabel setText:[NSString stringWithFormat:@"%.1f", heading.y]];
//	[self.zLabel setText:[NSString stringWithFormat:@"%.1f", heading.z]];
    
    // Compute and display the magnitude (size or strength) of the vector.
	//      magnitude = sqrt(x^2 + y^2 + z^2)
//	CGFloat magnitude = sqrt(heading.x*heading.x + heading.y*heading.y + heading.z*heading.z);
//    [magnitudeLabel setText:[NSString stringWithFormat:@"%.1f", magnitude]];
    
//    NSLog(@"X=%.1f, Y=%.1f, Z=%.1f", heading.x, heading.y, heading.z);
	
	// Update the graph with the new magnetic reading.
//	[self.graphView updateHistoryWithX:heading.x y:heading.y z:heading.z];
}

// This delegate method is invoked when the location managed encounters an error condition.
- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    if ([error code] == kCLErrorDenied) {
        // This error indicates that the user has denied the application's request to use location services.
        [manager stopUpdatingHeading];
    } else if ([error code] == kCLErrorHeadingFailure) {
        // This error indicates that the heading could not be determined, most likely because of strong magnetic interference.
    }
    UIAlertView *noCompassAlert = [[UIAlertView alloc] initWithTitle:@"Error!" message:@"Q paso?" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [noCompassAlert show];
}

#pragma mark - Public

- (IBAction)axisControlChanged:(id)sender
{
    NSInteger index = [(UISegmentedControl *)sender selectedSegmentIndex];
    self.axis = index;
}

#pragma mark - Setters

- (void)setMotionManagerOn:(BOOL)motionManagerOn
{
    NSCAssert([NSThread isMainThread], @"Require main thread");
    
    if ( motionManagerOn == _motionManagerOn ) {
        return;
    }
    
    _motionManagerOn = motionManagerOn;
    
    if ( motionManagerOn ) {
        // TODO: Safe using main Q? probs not. data arrives at high rate
        [self.motionManager startAccelerometerUpdatesToQueue:[NSOperationQueue mainQueue] withHandler:^(CMAccelerometerData *accelerometerData, NSError *error) {
            // code
            if ( self.motionManagerOn ) {
                CMAcceleration acc = accelerometerData.acceleration;
                double m = acc.x*acc.x + acc.y*acc.y + acc.z*acc.z;
                double value = sqrt(m);
                
                self.isMovingTooMuch = ( value > kHoldStillAccelerationLevel );                
            }
        }];
    } else {
        [self.motionManager stopAccelerometerUpdates];
    }
}

- (void)setState:(FinderState)state
{
    if ( state == _state ) {
        return;
    }
    
    BOOL holdStillHidden = YES;
    
    switch (state) {
        case FinderStateHoldStill:
            holdStillHidden = NO;
            break;
            
        default:
            break;
    }
    
    self.holdStillView.hidden = holdStillHidden;
    
    _state = state;
}

#pragma mark - Private

- (void)_updateMag {
    NSCAssert([NSThread isMainThread], @"Require main thread");
    [UIView animateWithDuration:kUIUpdateInterval animations:^{
        self.movingCircle.transform = CGAffineTransformMakeScale(self.m, self.m);        
    }];
}

@end
