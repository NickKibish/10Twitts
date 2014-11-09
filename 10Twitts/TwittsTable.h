//
//  TwittsTable.h
//  10Twitts
//
//  Created by Nick Kibish on 07.11.14.
//  Copyright (c) 2014 Nick Kibish. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TwittCell;
@interface TwittsTable : UITableViewController <UITableViewDataSource>
@property (strong, nonatomic) UIImage *chosenImage;
- (void)loadTwitts;
- (IBAction)refresh:(id)sender;
@end

@interface TwittCell : UITableViewCell <UIAlertViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>
@property (strong, nonatomic) TwittsTable *parentTable;

@property (strong, nonatomic) IBOutlet UILabel *displayName;
@property (strong, nonatomic) IBOutlet UILabel *twittwrNickName;
@property (strong, nonatomic) IBOutlet UILabel *dateLabel;
@property (strong, nonatomic) IBOutlet UILabel *twittLabel;
@property (strong, nonatomic) IBOutlet UIImageView *userAvatal;

- (IBAction)share:(id)sender;
@end