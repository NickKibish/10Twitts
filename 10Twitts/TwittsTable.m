//
//  TwittsTable.m
//  10Twitts
//
//  Created by Nick Kibish on 07.11.14.
//  Copyright (c) 2014 Nick Kibish. All rights reserved.
//

#define TweetColor [UIColor colorWithRed:83./255 green:173./255 blue:233./255 alpha:1.0]

#import "TwittsTable.h"
#import "STTwitter.h"
#import "AppDelegate.h"

static NSString *_twitterDisplayName = @"pinkfloyd";
@interface TwittsTable ()
@property (strong, nonatomic) NSArray *statuses;
@property (assign, nonatomic) NSInteger rowsCount;
@end

@implementation TwittsTable

- (void)loadTwitts
{
    AppDelegate *appDelegate = [AppDelegate delegate];
    STTwitterAPI *twitter = appDelegate.twitter;
    [twitter getUserTimelineWithScreenName:_twitterDisplayName
                                     count:10
                              successBlock:^(NSArray *statuses){
                                  if (self.statuses.count) {
                                      self.statuses = statuses;
                                      [self uploadTable];
                                  } else {
                                      self.statuses = statuses;
                                      [self.tableView reloadData];
                                  }
                                  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                      [self saveToDatabase];
                                  });
                                  [self.refreshControl endRefreshing];
                              }errorBlock:^(NSError *error){
                                  [self loadFromDatabase];
                                  [self.refreshControl endRefreshing];
                              }];
}

- (void)uploadTable
{
    NSMutableArray *indexPathes = [NSMutableArray array];
    for (int i = 0; i < self.statuses.count; i++) {
        [indexPathes insertObject:[NSIndexPath indexPathForRow:i inSection:0] atIndex:0];
    }
    [self.tableView reloadRowsAtIndexPaths:indexPathes withRowAnimation:UITableViewRowAnimationFade];
}

- (void)saveToDatabase
{
    AppDelegate *delegate = [AppDelegate delegate];
    NSManagedObjectContext *context = [delegate managedObjectContext];
    NSFetchRequest *allTweets = [[NSFetchRequest alloc] init];
    [allTweets setEntity:[NSEntityDescription entityForName:@"Twitts" inManagedObjectContext:context]];
    [allTweets setIncludesPropertyValues:NO];
    
    NSError * error = nil;
    NSArray * tweets = [context executeFetchRequest:allTweets error:&error];
    for (NSManagedObject *tweet in tweets) {
        [context deleteObject:tweet];
    }
    NSError *saveError = nil;
    [context save:&saveError];
    NSError *err;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:self.statuses
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:&err];
    NSString *jsonSTR = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    if ([jsonData length] > 0 && err == nil){
        NSLog(@"Successfully serialized the dictionary into data = %@",
              jsonData);
    }
    else if ([jsonData length] == 0 && err == nil){
        NSLog(@"No data was returned after serialization.");
    }
    else if (err != nil){
        NSLog(@"An error happened = %@", err);
    }
    
    
    NSEntityDescription *tweetData = [NSEntityDescription entityForName:@"Twitts"
                                                 inManagedObjectContext:context];
    NSManagedObject *tweetManagObj = [NSEntityDescription insertNewObjectForEntityForName:[tweetData name] inManagedObjectContext:context];
    [tweetManagObj setValue:jsonSTR forKey:@"json"];
    NSLog(@"JSON String:%@", jsonSTR);
    NSError *savingError;
    [context save:&savingError];
    if (savingError) {
        NSLog(@"Saving error: %@", savingError);
    }
}

- (void)loadFromDatabase
{
    AppDelegate *delegate = [AppDelegate delegate];
    NSManagedObjectContext *context = [delegate managedObjectContext];
    NSFetchRequest *allTweets = [[NSFetchRequest alloc] init];
    [allTweets setEntity:[NSEntityDescription entityForName:@"Twitts" inManagedObjectContext:context]];
    [allTweets setIncludesPropertyValues:NO];
    
    NSError * error = nil;
    NSArray * tweets = [context executeFetchRequest:allTweets error:&error];
    NSManagedObject *tweet = [tweets firstObject];
    NSString *jsonSTR = [tweet valueForKey:@"json"];
    NSLog(@"JSON %@", jsonSTR);
    NSData *data = [jsonSTR dataUsingEncoding:NSUTF8StringEncoding];
    NSArray *jsonObject = [NSJSONSerialization JSONObjectWithData:data
                                                          options:NSJSONReadingAllowFragments
                                                            error:&error];
    self.statuses = jsonObject;
    [self.tableView reloadData];
}

- (IBAction)refresh:(id)sender
{
    [self loadTwitts];
}

- (NSArray *)statuses
{
    if (!_statuses)
        _statuses = [NSArray array];
    return _statuses;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    
    self.refreshControl = [[UIRefreshControl alloc] init];
    self.refreshControl.backgroundColor = TweetColor;
    self.refreshControl.tintColor = [UIColor whiteColor];
    [self.refreshControl addTarget:self
                            action:@selector(loadTwitts)
                  forControlEvents:UIControlEventValueChanged];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    NSLog(@"Memory warning");
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.statuses count];
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
    if (!cell) {
        cell = [[TwittCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
    }
    cell.parentTable = self;
    
    NSDictionary *status = [self.statuses objectAtIndex:indexPath.row];
    NSString *tweetText = [status valueForKey:@"text"];
    NSNumber *isRetweeted = [status valueForKey:@"retweeted"];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
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
    cell.dateLabel.text = [status valueForKey:@"created_at"];
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

@end

@implementation TwittCell
- (IBAction)share:(id)sender
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Добавить фото?"
                                                    message:@"Хотите загрузить фото из библиотеки?"
                                                   delegate:self
                                          cancelButtonTitle:@"Нет"
                                          otherButtonTitles:@"Да", nil];
    [alert show];
}

#pragma mark - Alert View Delegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex) {
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        picker.delegate = self;
        picker.allowsEditing = YES;
        picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        [picker setModalPresentationStyle:UIModalPresentationPageSheet];
        
        [self.parentTable presentViewController:picker animated:YES completion:NULL];
    } else {
        [self shareTweetWithImage:nil];
    }
}

- (void)shareTweetWithImage:(UIImage *)image
{
    NSMutableArray *arr = [NSMutableArray arrayWithObject:self.twittLabel.text];
    if (image)
        [arr insertObject:image atIndex:1];
    UIActivityViewController *activityView = [[UIActivityViewController alloc] initWithActivityItems:arr
                                                                               applicationActivities:nil];
    activityView.popoverPresentationController.sourceView = self.twittLabel;
    [self.parentTable presentViewController:activityView
                                   animated:YES
                                 completion:nil];
}

#pragma mark - Image Picker Controller Delegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *chosenImage = info[UIImagePickerControllerEditedImage];
    
    [picker dismissViewControllerAnimated:YES completion:^{
        [self shareTweetWithImage:chosenImage];
    }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:^{
        [self shareTweetWithImage:nil];
    }];
}

@end
