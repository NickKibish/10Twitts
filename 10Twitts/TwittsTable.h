//
//  TwittsTable.h
//  10Twitts
//
//  Created by Nick Kibish on 07.11.14.
//  Copyright (c) 2014 Nick Kibish. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TwittsTable : UITableViewController
- (void)loadTwitts;
@end

@interface TwittCell : UITableViewCell
@property (strong, nonatomic) IBOutlet UILabel *displayName;
@property (strong, nonatomic) IBOutlet UILabel *twittwrNickName;
@property (strong, nonatomic) IBOutlet UILabel *dateLabel;
@property (strong, nonatomic) IBOutlet UILabel *twittLabel;
@property (strong, nonatomic) IBOutlet UIImageView *userAvatal;

@end