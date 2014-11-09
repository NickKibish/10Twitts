//
//  TwittsTable.m
//  10Twitts
//
//  Created by Nick Kibish on 07.11.14.
//  Copyright (c) 2014 Nick Kibish. All rights reserved.
//

#import "TwittsTable.h"
#import "STTwitter.h"
#import "AppDelegate.h"

static NSString *_twitterDisplayName = @"NickKibish";
@interface TwittsTable ()
@property (strong, nonatomic) NSArray *statuses;
@end

@implementation TwittsTable

- (void)loadTwitts
{
    AppDelegate *appDelegate = [AppDelegate delegate];
    STTwitterAPI *twitter = appDelegate.twitter;
    [twitter getUserTimelineWithScreenName:_twitterDisplayName
                                     count:10
                              successBlock:^(NSArray *statuses){
                                  self.statuses = statuses;
                                  [self.tableView reloadData];
                              }errorBlock:^(NSError *error){
                                  UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                                                  message:[error localizedDescription]
                                                                                 delegate:nil
                                                                        cancelButtonTitle:@"Ok"
                                                                        otherButtonTitles:nil];
                                  [alert show];
                              }];
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    NSLog(@"Memory warning");
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.statuses.count;
}

- (void)loadImage:(UIImageView *)imageView URL:(NSURL *)URL
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSData *data = [NSData dataWithContentsOfURL:URL];
        UIImage *image = [UIImage imageWithData:data];
        dispatch_async(dispatch_get_main_queue(), ^{
            imageView.image = image;
        });
    });
}

- (void)getUserImageForScreenName:(NSString *)screenName imageView:(UIImageView *)imageView
{
    AppDelegate *appDelegate = [AppDelegate delegate];
    NSURL *imageDir = [[appDelegate applicationDocumentsDirectory] URLByAppendingPathComponent:@"images"];
    NSString *fileName = [[imageDir URLByAppendingPathComponent:screenName] absoluteString];
    if ([[NSFileManager defaultManager] fileExistsAtPath:fileName]) {
        imageView.image = [UIImage imageWithContentsOfFile:fileName];
    } else {
        STTwitterAPI *twitter = appDelegate.twitter;
        [twitter profileImageFor:screenName
                    successBlock:^(id image) {
                        if (image) {
                            [UIImagePNGRepresentation(image) writeToFile:fileName atomically:YES];
                            dispatch_async(dispatch_get_main_queue(), ^{
                                imageView.image = image;
                            });
                        }
                    }errorBlock:^(NSError *error) {
                        NSLog(@"%@", [error description]);
                    }];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    TwittCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    if (!cell)
        cell = [[TwittCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
    
    NSDictionary *status = [self.statuses objectAtIndex:indexPath.row];
    NSString *tweetText = [status valueForKey:@"text"];
    NSNumber *isRetweeted = [status valueForKey:@"retweeted"];
    cell.userAvatal.image = nil;
    if ([isRetweeted boolValue]) {
        AppDelegate *appDelegate = [AppDelegate delegate];
        STTwitterAPI *twitter = appDelegate.twitter;
        NSString *screenName = [self screenNameFromRetweetedTwitt:tweetText];
        [self getUserImageForScreenName:screenName imageView:cell.userAvatal];
        [twitter getUserInformationFor:screenName
                          successBlock:^(NSDictionary *user) {
                              cell.displayName.text = [user valueForKey:@"name"];
                          }errorBlock:^(NSError *error) {
                              
                          }];
        cell.twittwrNickName.text = [NSString stringWithFormat:@"@%@", screenName];
        cell.twittLabel.text = [self tweetWithoutRetweetInfo:tweetText];
    } else {
        cell.twittLabel.text = tweetText;
        NSString *imageURL = [[status valueForKey:@"user"] valueForKey:@"profile_image_url"];
        
        cell.twittwrNickName.text = [NSString stringWithFormat:@"@%@", [[status valueForKey:@"user"] valueForKey:@"screen_name"]];
        cell.displayName.text = [[status valueForKey:@"user"] valueForKey:@"name"];
        NSURL *url = [NSURL URLWithString:imageURL];
        [self loadImage:cell.userAvatal URL:url];
    }
    
    return cell;
}

#pragma mark - Twitts
- (NSString *)screenNameFromRetweetedTwitt:(NSString *)tweet
{
    NSString *retw = [[tweet componentsSeparatedByString:@":"] firstObject];
    NSString *screenName = [[retw componentsSeparatedByString:@"@"] lastObject];
    return screenName;
}

- (NSString *)tweetWithoutRetweetInfo:(NSString *)tweetText
{
    NSMutableArray *arr = [NSMutableArray arrayWithArray:[tweetText componentsSeparatedByString:@":"]];
    [arr removeObjectAtIndex:0];
    NSString *result = [[arr valueForKey:@"description"] componentsJoinedByString:@":"];
    return result;
}

- (void)parseRetweetedTwitt
{
    
}

@end

@implementation TwittCell
@end