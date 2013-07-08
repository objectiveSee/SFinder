//
//  DRViewController.h
//  StudFinder
//
//  Created by Danny Ricciotti on 7/8/13.
//  Copyright (c) 2013 Danny Ricciotti. All rights reserved.
//

@interface DRStudFinderViewController : UIViewController <CLLocationManagerDelegate>

@property (nonatomic) IBOutlet UIView *holdStillView;

@property (nonatomic) IBOutlet UIImageView* mainCircle;
@property (nonatomic) IBOutlet UIImageView* movingCircle;

- (IBAction)axisControlChanged:(id)sender;

@end
