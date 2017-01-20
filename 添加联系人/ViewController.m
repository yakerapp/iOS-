//
//  ViewController.m
//  添加联系人
//
//  Created by yaker on 2017/1/20.
//  Copyright © 2017年 yaker. All rights reserved.
//

#import "ViewController.h"
#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>

@interface ViewController ()<ABNewPersonViewControllerDelegate,ABPeoplePickerNavigationControllerDelegate>

@property (nonatomic, assign) ABAddressBookRef addressBook;

@property (nonatomic, copy) NSString *phonenumber;

- (IBAction)addNewPersonClicked:(id)sender;

- (IBAction)addToParentPersonClicekd:(id)sender;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.phonenumber = @"15637829899";
    _addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
    
    //获取通讯录权限
    if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined) {
        //这里会在第一次运行时执行，之后打开应用将不会再执行，权限的判断由后面两个判断语句判断
        ABAddressBookRequestAccessWithCompletion(_addressBook, ^(bool granted, CFErrorRef error){
            //这里是权限选择后的回调，如果granted为true则表示允许访问
            
        });
    }else if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized){
        //允许访问通讯录
    }else {
        //访问通讯录被拒绝

    }
}
#pragma mark - 添加新建联系人
- (IBAction)addNewPersonClicked:(id)sender {
    if([self checkAddressBookAccess]){
        ABRecordRef record = ABPersonCreate();
        CFErrorRef error;
        ABRecordSetValue(record, kABPersonFirstNameProperty, (__bridge CFTypeRef)self.phonenumber, &error);
        // 添加联系人电话号码以及该号码对应的标签名
        ABMutableMultiValueRef multi = ABMultiValueCreateMutable(kABPersonPhoneProperty);
        ABMultiValueAddValueAndLabel(multi, (__bridge CFTypeRef)self.phonenumber, NULL, NULL);
        ABRecordSetValue(record, kABPersonPhoneProperty, multi, &error);
        [self addNewPerson:record];
    }else{
        UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"错误" message:@"没有获取通讯录的权限，请先在设置->隐私->通讯录中修改权限" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles: nil];
        [alert show];
    }
}

#pragma mark - 添加到现有联系人
- (IBAction)addToParentPersonClicekd:(id)sender {
    if([self checkAddressBookAccess]){
        [self showAllPerson];
    }else{
        UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"错误" message:@"没有获取通讯录的权限，请先在设置->隐私->通讯录中修改权限" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles: nil];
        [alert show];
    }
}

#pragma mark - 通讯录相关

#pragma mark - 添加联系人
- (void)addNewPerson:(ABRecordRef)record{
    ABNewPersonViewController *picker = [[ABNewPersonViewController alloc] init];
    picker.displayedPerson = record;
    picker.newPersonViewDelegate = self;
    UINavigationController *navigation = [[UINavigationController alloc] initWithRootViewController:picker];
    [self presentViewController:navigation animated:YES completion:nil];
}
- (void)newPersonViewController:(ABNewPersonViewController *)newPersonView didCompleteWithNewPerson:(nullable ABRecordRef)person{
    [self dismissViewControllerAnimated:YES completion:nil];
}
#pragma mark - 显示所有联系人
- (void)showAllPerson{
    ABPeoplePickerNavigationController *picker = [[ABPeoplePickerNavigationController alloc] init];
    picker.peoplePickerDelegate = self;
    NSArray *displayedItems = [NSArray arrayWithObjects:[NSNumber numberWithInt:kABPersonPhoneProperty],
                               [NSNumber numberWithInt:kABPersonEmailProperty],
                               [NSNumber numberWithInt:kABPersonBirthdayProperty], nil];
    picker.displayedProperties = displayedItems;
    [self presentViewController:picker animated:YES completion:nil];
}
- (void)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker didSelectPerson:(ABRecordRef)person{
    //读取电话多值
    ABMultiValueRef phone = ABRecordCopyValue(person, kABPersonPhoneProperty);
    CFErrorRef error;
    // 添加联系人电话号码以及该号码对应的标签名
    ABMutableMultiValueRef multi = ABMultiValueCreateMutable(kABPersonPhoneProperty);
    for (int k = 0; k<ABMultiValueGetCount(phone); k++)
    {
        NSString * personPhone = (__bridge NSString*)ABMultiValueCopyValueAtIndex(phone, k);
        ABMultiValueAddValueAndLabel(multi, (__bridge CFTypeRef)personPhone, NULL, NULL);
    }
    ABMultiValueAddValueAndLabel(multi, (__bridge CFTypeRef)self.phonenumber, NULL, NULL);
    ABRecordSetValue(person, kABPersonPhoneProperty, multi, &error);
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self addNewPerson:person];
    });
}
#pragma mark - 查看通讯录权限
/*
 * 没有权限时返回NO
 */
-(BOOL)checkAddressBookAccess
{
    switch (ABAddressBookGetAuthorizationStatus())
    {
        case  kABAuthorizationStatusAuthorized:
        case  kABAuthorizationStatusNotDetermined :{
            return YES;
        }
        case  kABAuthorizationStatusDenied:
        case  kABAuthorizationStatusRestricted:
        {
            return NO;
        }
            break;
        default:
            break;
    }
    return NO;
}

@end
